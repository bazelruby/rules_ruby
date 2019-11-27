load(":bundler.bzl", "install_bundler")
load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")
load("//ruby/private/toolchains:repository_context.bzl", "ruby_repository_context")

def _ruby_26_runtime_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
        },
        executable = False,
    )

ruby_26_runtime = repository_rule(
    implementation = _ruby_26_runtime_impl,
    attrs = {
        "_init_loadpath_rb": attr.label(
            default = "%s//:ruby/tools/init_loadpath.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_buildfile_template": attr.label(
            default = "%s//ruby/private/toolchains:BUILD.26_runtime.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private/toolchains:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
