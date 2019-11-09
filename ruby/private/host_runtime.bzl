load(":bundler.bzl", "install_bundler")

def _eval_ruby(ctx, interpreter, script, options=None):
  arguments = ['env', '-i', interpreter]
  if options:
    arguments.extend(options)
  arguments.extend(['-e', script])

  environment = {"RUBYOPT": "--disable-gems"}

  result = ctx.execute(arguments, environment=environment)
  if result.return_code:
    message = "Failed to evaluate ruby snippet with {}: {}".format(
        interpreter, result.stderr)
    fail(message)
  return result.stdout

def _rbconfig(ctx, name):
  options = ['-rrbconfig']
  script = 'print RbConfig::CONFIG[%s]' % repr(name)
  _eval_ruby(ctx, script=script, options=options)

BUILDFILE_CONTENT = """
load(
  "@rules_ruby//ruby:def.bzl",
  "rb_library",
)

package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "ruby",
    srcs = ["ruby.sh"],
    data = [{ruby_path}, ":runtime"],
)

# exports_files(["init_loadpath.rb"])
filegroup(
  name = "init_loadpath",
  srcs = ["init_loadpath.rb"],
  data = ["loadpath.lst"],
)

filegroup(
  name = "bundler",
  srcs = ["bundler/exe/bundler"],
  data = glob(["bundler/**/*.rb"]),
)

filegroup(
    name = "runtime",
    srcs = glob(
        include = ["**/*"],
        exclude = [
          {ruby_path},
          "ruby",
          "init_loadpath.rb",
          "loadpath.lst",
          "BUILD.bazel",
          "WORKSPACE",
        ],
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

def _ruby_host_runtime_impl(ctx):
  # Locates path to the interpreter
  if ctx.attr.interpreter_path:
    interpreter_path = ctx.path(ctx.attr.interpreter_path)
  else:
    interpreter_path = ctx.which("ruby")
  if not interpreter_path:
    fail(
        "Command 'ruby' not found. Set $PATH or specify interpreter_path",
        "interpreter_path",
    )
  interpreter_path = str(interpreter_path)

  rel_interpreter_path = str(interpreter_path)
  if rel_interpreter_path.startswith('/'):
    rel_interpreter_path = rel_interpreter_path[1:]

  # Places SDK
  ctx.symlink(interpreter_path, rel_interpreter_path)
  ctx.symlink(ctx.attr._init_loadpath_rb, "init_loadpath.rb")

  interpreter_wrapper = """
  #!/bin/sh
  DIR=`dirname $0`
  exec $DIR/%s $*
  """
  ctx.file('ruby.sh', interpreter_wrapper % rel_interpreter_path, executable=True)

  install_bundler(
      ctx,
      interpreter_path,
      ctx.path(ctx.attr._install_bundler).realpath,
      'bundler',
  )

  paths = _eval_ruby(ctx, interpreter_path, 'print $:.join("\\n")')
  paths = sorted(paths.split("\n"))

  rel_paths = []
  for i, path in enumerate(paths):
    # Assuming that absolute paths start with "/".
    # TODO support windows
    if path.startswith('/'):
      rel_path = path[1:]
    else:
      rel_path = path

    if not _is_subpath(rel_path, rel_paths):
      ctx.symlink(path, rel_path)

    rel_paths.append(rel_path)

  ctx.file("loadpath.lst", "\n".join(rel_paths))

  content = BUILDFILE_CONTENT.format(
      ruby_path = repr(rel_interpreter_path),
  )
  ctx.file("BUILD.bazel", content, executable=False)

ruby_host_runtime = repository_rule(
    implementation = _ruby_host_runtime_impl,
    attrs = {
        "interpreter_path": attr.string(),

        "_init_loadpath_rb": attr.label(
            default = "@rules_ruby//:ruby/tools/init_loadpath.rb",
            allow_single_file = True,
        ),
        "_install_bundler": attr.label(
            default = "@rules_ruby//ruby/private:install-bundler.rb",
            allow_single_file = True,
        ),
    },
)
