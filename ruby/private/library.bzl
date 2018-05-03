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

  deps = _transitive_deps(ctx.attr.deps)
  srcs = deps.transitive_srcs + ctx.files.srcs
  runfiles = ctx.runfiles(
      files = srcs.to_list(),
      collect_default = True,
      collect_data = True,
  )
  return [
      DefaultInfo(
        runfiles = runfiles,
      ),
      RubyLibrary(
          transitive_ruby_srcs = deps.transitive_srcs,
      ),
  ]


ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "deps": attr.label_list(
            providers = [RubyLibrary]
        ),
        "data": attr.label_list(
            allow_files = True,
            cfg = "data",
        ),
    },
)
