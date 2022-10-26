load(":constants.bzl", "RULES_RUBY_WORKSPACE_NAME")
load(":providers.bzl", "RubyRuntimeToolchainInfo")

def _ruby_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            ruby_runtime = RubyRuntimeToolchainInfo(
                interpreter = ctx.attr.interpreter,
                runtime = ctx.files.runtime,
                headers = ctx.attr.headers,
                rubyopt = ctx.attr.rubyopt,
            ),
        ),
    ]

_ruby_toolchain = rule(
    implementation = _ruby_toolchain_impl,
    attrs = {
        "interpreter": attr.label(
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "target",
        ),
        "runtime": attr.label(
            mandatory = True,
            allow_files = True,
            cfg = "target",
        ),
        "headers": attr.label(
            mandatory = True,
            allow_files = True,
            cfg = "target",
        ),
        "rubyopt": attr.string_list(
            default = [],
        ),
    },
)

def ruby_toolchain(
        name,
        interpreter,
        runtime,
        headers,
        rubyopt = [],
        rules_ruby_workspace = RULES_RUBY_WORKSPACE_NAME,
        **kwargs):
    impl_name = name + "_sdk"
    _ruby_toolchain(
        name = impl_name,
        interpreter = interpreter,
        runtime = runtime,
        headers = headers,
        rubyopt = rubyopt,
    )

    native.toolchain(
        name = name,
        toolchain_type = "%s//ruby:toolchain_type" % rules_ruby_workspace,
        toolchain = ":%s" % impl_name,
        **kwargs
    )
