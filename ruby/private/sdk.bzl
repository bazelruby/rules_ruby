load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:ruby_runtime.bzl",
    _ruby_runtime = "ruby_runtime",
)

def ruby_register_toolchains(version = "host"):
    """Registersr ruby toolchains in the WORKSPACE file."""

    supported_versions = ["host", "2.6.3", "2.6.5"]
    if version in supported_versions:
        _ruby_runtime(
            name = "org_ruby_lang_ruby_toolchain",
            version = version,
        )
    else:
        fail("unknown ruby version in `ruby_register_toolchains`")

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )
