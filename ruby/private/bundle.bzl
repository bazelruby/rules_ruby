def _get_interpreter_label(repository_ctx, ruby_sdk):
  # TODO Support windows as rules_nodejs does
  return Label("%s//:ruby.sh" % ruby_sdk)

def _get_bundler_label(repository_ctx, ruby_sdk):
  # TODO Support windows as rules_nodejs does
  return Label("%s//:bundler/exe/bundler" % ruby_sdk)

def _get_bundler_lib_label(repository_ctx, ruby_sdk):
  # TODO Support windows as rules_nodejs does
  return Label("%s//:bundler/lib" % ruby_sdk)

def rb_bundle_impl(ctx):
  ctx.symlink(ctx.attr.gemfile, "Gemfile")
  ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
#  if ctx.attr.gem:
#    ctx.symlink(ctx.path(ctx.attr.gemfile).dirname + '/' + ctx.attr.gem + '.gemspec', ctx.attr.gem + '.gemspec')
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
      },
  )


rb_bundle = repository_rule(
    implementation = rb_bundle_impl,
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_host",
        ),
        "gemfile": attr.label(
            allow_single_file = True
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True
        ),
        "gem": attr.label(
            allow_single_file = True
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),

        "_buildfile_template": attr.label(
            default = "@rules_ruby//ruby/private:bundle_buildfile.tpl",
            allow_single_file = True,
        ),
    },
)
