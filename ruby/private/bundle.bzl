_BUILD_FILE = """
load(
  "@com_github_yugui_rules_ruby//ruby:def.bzl",
  "ruby_library",
)

package(default_visibility = ["//visibility:public"])

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":libs"],
)

ruby_library(
  name = "libs",
  srcs = glob(["lib/**/*"]),
  rubyopt = ["-r../{}/lib/bundler/setup.rb"],
)
"""

def _get_interpreter_label(repository_ctx, ruby_sdk):
  # TODO(yugui) Support windows as rules_nodejs does
  return Label("%s//:ruby.sh" % ruby_sdk)

def _get_bundler_label(repository_ctx, ruby_sdk):
  # TODO(yugui) Support windows as rules_nodejs does
  return Label("%s//:bundler/exe/bundler" % ruby_sdk)

def _get_bundler_lib_label(repository_ctx, ruby_sdk):
  # TODO(yugui) Support windows as rules_nodejs does
  return Label("%s//:bundler/lib" % ruby_sdk)

def bundle_install_impl(ctx):
  ctx.symlink(ctx.attr.gemfile, "Gemfile")
  ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")

  ruby = _get_interpreter_label(ctx, ctx.attr.ruby_sdk)
  bundler = _get_bundler_label(ctx, ctx.attr.ruby_sdk)

  args = [
      'env', '-i',
      ctx.path(ruby),
      '--disable-gems',
      '-I', ctx.path(bundler).dirname.dirname.get_child('lib'),
      ctx.path(bundler),
      'install',
      '--deployment',
      '--standalone',
      '--frozen',
      '--binstubs=bin',
      '--path=lib',
  ]
  result = ctx.execute(args, quiet=False)
  if result.return_code:
    fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))
  ctx.file('BUILD.bazel', _BUILD_FILE.format(ctx.name))


bundle_install = repository_rule(
    implementation = bundle_install_impl,
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_host",
        ),
        "gemfile": attr.label(
            allow_single_file = True,
            cfg = "data",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True,
            cfg = "data",
        ),
    },
)
