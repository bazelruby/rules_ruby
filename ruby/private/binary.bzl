load(
    ":providers.bzl",
    "RubyLibrary",
)
load(
    ":helpers.bzl",
    _transitive_deps = "transitive_deps",
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
    fail(
        ("main must be present unless the name of the rule matches to one " +
         "of the srcs"),
        "main",
    )

  executable = ctx.actions.declare_file(ctx.attr.name)
  deps = _transitive_deps(
      ctx,
      extra_files = init_files + [interpreter, executable],
      extra_deps = sdk.init_files + [sdk.interpreter],
  )

  rubyopt = reversed(deps.rubyopt.to_list())
  rubyopt += ["-I%s" % inc for inc in deps.incpaths.to_list()]

  ctx.actions.expand_template(
      template = ctx.file._wrapper_template,
      output = executable,
      substitutions = {
          "{interpreter}": interpreter.short_path,
          "{init_flags}": init_flags,
          "{rubyopt}": " ".join(rubyopt),
          "{main}": main.short_path,
      },
      is_executable = True,
  )
  return [DefaultInfo(
      executable = executable,
      default_runfiles = deps.default_files,
      data_runfiles = deps.data_files,
  )]

_ATTRS = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
        providers = [RubyLibrary]
    ),
    "includes": attr.string_list(),
    "rubyopt": attr.string_list(),
    "data": attr.label_list(
        allow_files = True,
        cfg = "data",
    ),
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
}

ruby_binary = rule(
    implementation = _ruby_binary_impl,
    attrs = _ATTRS,
    executable = True,
)

ruby_test = rule(
    implementation = _ruby_binary_impl,
    attrs = _ATTRS,
    test = True,
)
