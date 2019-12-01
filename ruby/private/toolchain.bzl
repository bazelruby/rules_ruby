load(":constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

RubyRuntimeInfo = provider(
    doc = "Information about a Ruby interpreter, related commands and libraries",
    fields = {
        "interpreter": "A label which points the Ruby interpreter",
        "bundler": "A label which points bundler command",
        "runtime": "A list of labels which points runtime libraries",
        "rubyopt": "A list of strings which should be passed to the interpreter as command line options",
        "is_host": "True only if the runtime is the host ruby ",
    },
)

def _rb_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        ruby_runtime = RubyRuntimeInfo(
            interpreter = ctx.attr.interpreter,
            bundler = ctx.attr.bundler,
            runtime = ctx.files.runtime,
            rubyopt = ctx.attr.rubyopt,
            is_host = ctx.attr.is_host,
        ),
    )]

_rb_toolchain = rule(
    implementation = _rb_toolchain_impl,
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
        "runtime": attr.label(
            mandatory = True,
            allow_files = True,
            cfg = "target",
        ),
        "rubyopt": attr.string_list(
            default = [],
        ),
        "is_host": attr.bool(default = False),
    },
)

def rb_toolchain(
        name,
        interpreter,
        bundler,
        runtime,
        rubyopt = [],
        is_host = False,
        rules_ruby_workspace = RULES_RUBY_WORKSPACE_NAME,
        **kwargs):
    impl_name = name + "_sdk"
    _rb_toolchain(
        name = impl_name,
        interpreter = interpreter,
        bundler = bundler,
        runtime = runtime,
        rubyopt = rubyopt,
        is_host = is_host,
    )

    native.toolchain(
        name = name,
        toolchain_type = "%s//ruby:toolchain_type" % rules_ruby_workspace,
        toolchain = ":%s" % impl_name,
        **kwargs,
    )
