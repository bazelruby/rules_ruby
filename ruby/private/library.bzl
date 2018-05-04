load(
    ":providers.bzl",
    "RubyLibrary",
)
load(
    ":helpers.bzl",
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
      ),
      RubyLibrary(
          transitive_ruby_srcs = deps.srcs,
          ruby_incpaths = deps.incpaths,
      ),
  ]


ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "includes": attr.string_list(),
        "deps": attr.label_list(
            providers = [RubyLibrary]
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
    },
)
