def _get_interpreter_label(repository_ctx, ruby_sdk):
  # TODO(yugui) Support windows as rules_nodejs does
  return Label("%s//:ruby" % ruby_sdk)

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

  exclude = []
  for gem, globs in ctx.attr.excludes.items():
    expanded = ["lib/ruby/*/gems/%s-*/%s" % (gem, glob) for glob in globs]
    exclude.extend(expanded)

  ctx.template(
      'BUILD.bazel',
      ctx.attr._buildfile_template,
      substitutions = {
          "{repo_name}": ctx.name,
          "{exclude}": repr(exclude),
          "{workspace_name}": ctx.attr.rules_ruby_workspace,
      },
  )


bundle_install = repository_rule(
    implementation = bundle_install_impl,
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_host",
        ),
        "gemfile": attr.label(
            allow_single_file = True,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True,
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),

        "rules_ruby_workspace": attr.string(
            default = "@com_github_yugui_rules_ruby",
            doc = "The workspace name of rules_ruby. Just a workaround of bazelbuild/bazel#3493",
        ),

        "_buildfile_template": attr.label(
            default = "@com_github_yugui_rules_ruby//ruby/private:bundle_buildfile.tpl",
            allow_single_file = True,
        ),
    },
)
