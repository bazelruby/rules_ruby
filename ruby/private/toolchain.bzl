load(":constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

RubyRuntimeInfo = provider(
    doc = "Information about a Ruby interpreter, related commands and libraries", 
    fields = {
        "interpreter": "A label which points the Ruby interpreter",
        "bundler": "A label which points bundler command",
        "init_files": "A list of labels which points initialization libraries",
        "runtime": "A list of labels which points runtime libraries",
        "rubyopt": "A list of strings which should be passed to the interpreter as command line options" ,
    }
)

def _ruby_toolchain_impl(ctx):
  return [platform_common.ToolchainInfo(
      ruby_runtime = RubyRuntimeInfo(
          interpreter = ctx.attr.interpreter,
          bundler = ctx.attr.bundler,
          init_files = ctx.attr.init_files,
          runtime = ctx.files.runtime,
          rubyopt = ctx.attr.rubyopt,
      ),
  )]

_ruby_toolchain = rule(
    implementation = _ruby_toolchain_impl,
    attrs = {
        "interpreter": attr.label(
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "target",
        ),
        "bundler": attr.label(
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "target",
        ),
        "init_files": attr.label_list(
            allow_files = True,
            cfg = "target",
        ),
        "runtime": attr.label(
            mandatory = True,
            allow_files = True,
            cfg = "target",
        ),
        "rubyopt": attr.string_list(
            default = [],
        ),
    },
)

def ruby_toolchain(name,
                   interpreter,
                   bundler,
                   runtime,
                   init_files=[],
                   rubyopt=[],
                   rules_ruby_workspace=RULES_RUBY_WORKSPACE_NAME,
                   **kwargs):
  impl_name = name + "_sdk"
  _ruby_toolchain(
      name = impl_name,
      interpreter = interpreter,
      bundler = bundler,
      init_files = init_files,
      rubyopt = rubyopt,
      runtime = runtime,
  )

  native.toolchain(
      name = name,
      toolchain_type = "%s//ruby:toolchain_type" % rules_ruby_workspace,
      toolchain = ":%s" % impl_name,
      **kwargs
  )
