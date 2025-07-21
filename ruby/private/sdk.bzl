load(
    "@bazelruby_rules_ruby//ruby/private/toolchains:ruby_runtime.bzl",
    _ruby_runtime = "ruby_runtime",
)

def rules_ruby_select_sdk(version = "host"):
    """Registers ruby toolchains in the WORKSPACE file."""

    supported_versions = [
        "host",
        "2.7.0",
        "2.7.1",
        "2.7.2",
        "2.7.3",
        "2.7.4",
        "2.7.5",
        "2.7.6",
        "3.0.0",
        "3.0.1",
        "3.0.2",
        "3.0.3",
        "3.0.4",
        "3.1.0",
        "3.1.1",
        "3.1.2",
        "3.2.0",
    ]

    if version in supported_versions:
        _ruby_runtime(
            name = "org_ruby_lang_ruby_toolchain",
            version = version,
        )
    else:
        fail("rules_ruby_select_sdk: unsupported ruby version '%s' not in '%s'" % (version, supported_versions))

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )
