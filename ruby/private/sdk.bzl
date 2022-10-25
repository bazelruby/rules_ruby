load(
    "@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl",
    _ruby_runtime = "ruby_runtime",
)

def rules_ruby_select_sdk(version = "host"):
    """Registers ruby toolchains in the WORKSPACE file."""

    supported_versions = [
        "host",
        "2.5.8",
        "2.5.9",
        "2.6.3",
        "2.6.4",
        "2.6.5",
        "2.6.6",
        "2.6.7",
        "2.6.8",
        "2.6.9",
        "2.7.1",
        "2.7.2",
        "2.7.3",
        "2.7.4",
        "2.7.5",
        "3.0.0",
        "3.0.1",
        "3.0.2",
        "3.0.3",
        "3.1.0",
        "3.1.1",
        "jruby-9.2.21.0",
        "jruby-9.3.6.0",
    ]

    for v in sorted(supported_versions, reverse = True):
        if v.startswith(version):
            supported_version = v
            break

    if not supported_version:
        fail("rules_ruby_select_sdk: unsupported ruby version '%s' not in '%s'" % (version, supported_versions))

    _ruby_runtime(
        name = "org_ruby_lang_ruby_toolchain",
        version = supported_version,
    )

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )
