RubyLibrary = provider(
    fields = ["transitive_ruby_srcs"],
)

def _transitive_deps(deps):
  transitive_srcs = depset()
  for d in deps:
    if RubyLibrary in d:
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
    "data": attr.label_list(
        allow_files = True,
        cfg = "data",
    ),
}

ruby_library = rule(
    implementation = _ruby_library_impl,
    attrs = _common_attrs,
)


def _ruby_binary_impl(ctx):
  sdk = ctx.attr.toolchain[platform_common.ToolchainInfo]
  interpreter = sdk.interpreter[DefaultInfo].files_to_run.executable
  init_files = sdk.init_files

  init_flags = " ".join(["-r%s" % f.short_path for f in init_files])

  executable = ctx.actions.declare_file(ctx.attr.name)
  ctx.actions.expand_template(
      template = ctx.file._wrapper_template,
      output = executable,
      substitutions = {
          "{interpreter}": interpreter.short_path,
          "{init_flags}": init_flags,
      },
      is_executable = True,
  )

  deps = _transitive_deps(ctx.attr.deps + [sdk.interpreter])
  srcs = deps.transitive_srcs + ctx.files.srcs
  files = srcs + init_files + [interpreter]
  runfiles = ctx.runfiles(
      files = files.to_list(),
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
            providers = [platform_common.ToolchainInfo],
        ),

        "_wrapper_template": attr.label(
          allow_single_file = True,
          default = "binary_wrapper.tpl",
        ),
    },
    executable = True,
)
