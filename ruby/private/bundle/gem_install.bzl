load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")

# Gem install is a rule that takes a Gemfile and Gemfile.lock and installs
def _gem_install_impl(ctx):
    if not ctx.attr.srcs and not ctx.attr.deps:
        fail("At least srcs or deps must be present")

    deps = _transitive_deps(ctx)
    return [
        DefaultInfo(
            default_runfiles = deps.default_files,
            data_runfiles = deps.data_files,
        ),
        RubyLibrary(
            transitive_ruby_srcs = deps.srcs,
            ruby_incpaths = deps.incpaths,
            rubyopt = deps.rubyopt,
        ),
    ]

gem_install = rule(
    implementation = _gem_install_impl,
    attrs = {
        "gemfile": attr.label_list(
            allow_files = True,
        ),
        "includes": attr.string_list(),
        "rubyopt": attr.string_list(),
        "deps": attr.label_list(
            providers = [RubyLibrary],
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
    },
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
