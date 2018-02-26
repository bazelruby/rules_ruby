def _eval_ruby(ctx, script, options=None):
  arguments = ['env', '-i', ctx.attr.interpreter_path]
  if options:
    arguments.extend(options)
  arguments.extend(['-e', script])

  environment = {"RUBYOPT": "--disable-gems"}

  result = ctx.execute(arguments, environment=environment)
  if result.return_code:
    message = "Failed to evaluate ruby snippet with {}: {}".format(
        ctx.attr.interpreter_path, result.stderr)
    fail(message)
  return result.stdout

def _rbconfig(ctx, name):
  options = ['-rrbconfig']
  script = 'print RbConfig::CONFIG[%s]' % repr(name)
  _eval_ruby(ctx, script=script, options=options)

BUILDFILE_CONTENT = """
package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "ruby",
    srcs = [{ruby_path}],
    data = [":runtime"],
)

filegroup(
    name = "runtime",
    srcs = glob(
        include = ["**/*"],
        exclude = ["init_loadpath.rb"],
    ),
)
"""

def _is_subpath(path, ancestors):
  for ancestor in ancestors:
    if not ancestor.endswith('/'):
      ancestor += '/'
    if path.startswith(ancestor):
      return True
  return False

def _system_ruby_runtime_impl(ctx):
  ruby_path = ctx.attr.interpreter_path
  if ruby_path.startswith('/'):
    ruby_path = ruby_path[1:]
  ctx.symlink(ctx.attr.interpreter_path, ruby_path)
  ctx.symlink(ctx.attr._init_loadpath_rb, "init_loadpath.rb")

  paths = _eval_ruby(ctx, 'print $:.join("\\n")')
  paths = sorted(paths.split("\n"))

  rel_paths = []
  for i, path in enumerate(paths):
    # Assuming that absolute paths start with "/".
    # TODO(yugui) support windows
    if path.startswith('/'):
      rel_path = path[1:]
    else:
      rel_path = path

    if not _is_subpath(rel_path, rel_paths):
      ctx.symlink(path, rel_path)

    rel_paths.append(rel_path)

  ctx.file("loadpath.lst", "\n".join(rel_paths))

  content = BUILDFILE_CONTENT.format(
      ruby_path = repr(ruby_path),
  )
  ctx.file("BUILD.bazel", content, executable=False)

_system_ruby_runtime = repository_rule(
    implementation = _system_ruby_runtime_impl,
    attrs = {
        "interpreter_path": attr.string(),
        "files": attr.label_list(default=[]),

        "_init_loadpath_rb": attr.label(
            default = ":ruby/tools/init_loadpath.rb",
            allow_single_file = True,
        ),
    },
)

def ruby_runtime(name, files=None, interpreter=None, interpreter_path=None):
  # TODO(yugui) support ruby interpereters in the current repo
  # TODO(yugui) support installing the specified version of ruby from source
  _system_ruby_runtime(
      name = name,
      files = files,
      interpreter_path = interpreter_path,
  )
