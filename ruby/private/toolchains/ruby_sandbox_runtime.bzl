load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

def _ruby_sandbox_runtime_impl(ctx):
    print("download and extract ruby")
    ctx.download_and_extract(
        url = "https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz",
        sha256 = "577fd3795f22b8d91c1d4e6733637b0394d4082db659fccf224c774a2b1c82fb",
        stripPrefix = "ruby-2.6.3",
    )

    quiet = False # for debugging
    print("autoconf")
    ctx.execute(
        ["autoconf"],
        quiet=quiet
        # environment = ctx.os.environ,
        # working_directory = str(git_repo.directory),
    )

    print("configure --prefix=%s/build" % ctx.path("ruby").dirname)
    ctx.execute(
        ["./configure", ("--prefix=%s/build" % ctx.path("ruby").dirname)],
        quiet=quiet
        # environment = ctx.os.environ,
        # working_directory = str(git_repo.directory),
    )

    print("make ruby")
    ctx.execute(
        ["make", "install"],
        quiet=quiet
        # environment = ctx.os.environ,
        # working_directory = str(git_repo.directory),
    )

    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
        },
        executable = False,
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
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private/toolchains:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
