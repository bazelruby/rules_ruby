def _ruby_library_impl(ctx):
  if not ctx.attr.srcs and not ctx.attr.deps:
    fail("At least srcs or deps must be present")

  runfiles = ctx.runfiles(
      files = ctx.attr.srcs,
      collect_default = True,
  )
  return [DefaultInfo(
      runfiles = runfiles,
  )]


_common_attrs = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
    ),
}

ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = _common_attrs,
    toolchains = ["@com_github_yugui_rule_ruby//ruby/toolchain:toolchain"],
)


def _ruby_binary_impl(ctx):
  executable = ctx.actions.declare_file(ctx.attr.name)

  runfiles = ctx.runfiles(
      files = ctx.attr.srcs
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
    },
    toolchains = ["@com_github_yugui_rule_ruby//ruby/toolchain:toolchain"],
)
