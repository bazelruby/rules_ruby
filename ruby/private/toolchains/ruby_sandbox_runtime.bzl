load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

def _ruby_sandbox_runtime_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
        },
        executable = False,
    )

    ctx.template(
        "ruby",
        ctx.attr._interpreter_wrapper_template,
        substitutions = {
            "{workspace_name}": ctx.name,
            "{rel_interpreter_path}": "asd",
        },
    )


ruby_sandbox_runtime = repository_rule(
    implementation = _ruby_sandbox_runtime_impl,
    attrs = {
        "_buildfile_template": attr.label(
            default = "%s//ruby/private/toolchains:BUILD.sandbox_runtime.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_ruby": attr.label(
            default = "@ruby_sandbox//:ruby",
        ),
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private/toolchains:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
