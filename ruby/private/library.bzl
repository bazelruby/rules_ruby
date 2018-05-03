RubyLibrary = provider(
    fields = ["transitive_ruby_srcs"],
)

def _transitive_deps(deps):
  transitive_srcs = depset()
  data_files = depset()
  for d in deps:
    if RubyLibrary in d:
      transitive_srcs += d[RubyLibrary].transitive_ruby_srcs
    data_files += d[DefaultInfo].data_runfiles.files

  return struct(
      transitive_srcs = transitive_srcs,
      data_files = data_files,
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
  init_files = [f for t in sdk.init_files for f in t.files]
  init_flags = " ".join(["-r%s" % f.short_path for f in init_files])

  main = ctx.file.main
  if not main:
    expected_name = "%s.rb" % ctx.attr.name
    for f in ctx.attr.srcs:
      if f.label.name == expected_name:
        main = f.files.to_list()[0]
        break
  if not main:
    fail("main must be present unless the name of the rule matches to one of the srcs", "main")

  executable = ctx.actions.declare_file(ctx.attr.name)
  ctx.actions.expand_template(
      template = ctx.file._wrapper_template,
      output = executable,
      substitutions = {
          "{interpreter}": interpreter.short_path,
          "{init_flags}": init_flags,
          "{main}": main.short_path,
      },
      is_executable = True,
  )

  deps = _transitive_deps(ctx.attr.deps + [sdk.interpreter] + sdk.init_files)
  srcs = deps.transitive_srcs + ctx.files.srcs
  files = srcs + deps.data_files + init_files + [interpreter, executable]
  runfiles = ctx.runfiles(
      files = files.to_list(),
      collect_default = True,
      collect_data = True,
  )
  data_runfiles = ctx.runfiles(
      files = deps.data_files.to_list(),
  )
  return [DefaultInfo(
      executable = executable,
      default_runfiles = runfiles,
      data_runfiles = data_runfiles,
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
