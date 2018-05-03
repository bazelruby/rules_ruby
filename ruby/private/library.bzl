RubyLibrary = provider(
    fields = ["transitive_ruby_srcs"],
)

def _transitive_deps(deps):
  transitive_srcs = depset()
  for d in deps:
    transitive_srcs += d[RubyLibrary].transitive_ruby_srcs

  return struct(
      transitive_srcs = transitive_srcs
   )

def _ruby_library_impl(ctx):
  if not ctx.attr.srcs and not ctx.attr.deps:
    fail("At least srcs or deps must be present")

  deps = _transitive_deps(ctx.attr.deps)
  srcs = deps.transitive_srcs + ctx.files.srcs
  runfiles = ctx.runfiles(
      files = srcs.to_list(),
      collect_default = True,
  )
  return [
      DefaultInfo(
        runfiles = runfiles,
      ),
      RubyLibrary(
          transitive_ruby_srcs = deps.transitive_srcs,
      ),
  ]


_common_attrs = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
        providers = [RubyLibrary]
    ),
}

ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = _common_attrs,
)


def _ruby_binary_impl(ctx):
  executable = ctx.actions.declare_file(ctx.attr.name)
  sh = """
#!/bin/sh -e
echo "PWD: $PWD",
echo "\$0: $0",
find .
  """
  ctx.actions.write(executable, sh, is_executable=True)

  deps = _transitive_deps(ctx.attr.deps)
  srcs = deps.transitive_srcs + ctx.files.srcs
  runfiles = ctx.runfiles(
      files = srcs.to_list(),
      collect_default = True,
  )
  return [DefaultInfo(
      executable = executable,
      runfiles = runfiles,
  )]

ruby_binary = rule(
    implementation = _ruby_binary_impl,
    attrs = _common_attrs + {
        "main": attr.label(
            allow_single_file = True,
        ),
        "toolchain": attr.label(
            default = "@com_github_yugui_rules_ruby//ruby/toolchain:ruby_sdk",
        )
    },
    executable = True,
)
