load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

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
        "env",
        "-i",
        ctx.path(ruby),
        "--disable-gems",
        "-I",
        ctx.path(bundler).dirname.dirname.get_child("lib"),
        ctx.path(bundler),
        "install",
        "--deployment",
        "--standalone",
        "--frozen",
        "--binstubs=bin",
        "--path=lib",
    ]
    result = ctx.execute(args, quiet = False)
    if result.return_code:
        fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))

    exclude = []
    for gem, globs in ctx.attr.excludes.items():
        expanded = ["lib/ruby/*/gems/%s-*/%s" % (gem, glob) for glob in globs]
        exclude.extend(expanded)

    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{repo_name}": ctx.name,
            "{exclude}": repr(exclude),
            "{workspace_name}": RULES_RUBY_WORKSPACE_NAME,
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
        "_buildfile_template": attr.label(
            default = "%s//ruby/private/bundle:BUILD.bundle.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "The template of BUILD files for installed gem bundles",
            allow_single_file = True,
        ),
    },
)
