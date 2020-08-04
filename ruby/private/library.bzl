"""
Constants
"""

load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")
load(":providers.bzl", "RubyLibraryInfo")
load(
    "//ruby/private/tools:deps.bzl",
    _transitive_deps = "transitive_deps",
)

def _ruby_library_impl(ctx):
    if not ctx.attr.srcs and not ctx.attr.deps:
        fail("At least srcs or deps must be present")

    deps = _transitive_deps(ctx)
    return [
        DefaultInfo(
            default_runfiles = deps.default_files,
            data_runfiles = deps.data_files,
            files = deps.srcs,
        ),
        RubyLibraryInfo(
            transitive_ruby_srcs = deps.srcs,
            ruby_incpaths = deps.incpaths,
            rubyopt = deps.rubyopt,
        ),
    ]

ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "includes": attr.string_list(),
        "rubyopt": attr.string_list(),
        "deps": attr.label_list(
            providers = [RubyLibraryInfo],
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
    },
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
