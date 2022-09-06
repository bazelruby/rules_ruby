load(
    "@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl",
    _ruby_runtime = "ruby_runtime",
)

def register_ruby_toolchain(name, version = "system"):
    """Registers ruby toolchains in the WORKSPACE file."""

    supported_versions = [
        "system",
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

    for v in sorted(supported_versions, reverse=True):
        if v.startswith(version):
            supported_version = v
            break

    if not supported_version:
        fail("register_ruby_toolchain: unsupported ruby version '%s' not in '%s'" % (version, supported_versions))

    _ruby_runtime(
        name = name,
        version = supported_version,
    )

    _ruby_runtime(
        name = "rules_ruby_default_toolchain",
        version = supported_version,
    )

    native.register_toolchains(
        "@%s//:toolchain" % name,
    )
    native.register_toolchains(
        "@rules_ruby_default_toolchain//:toolchain",
    )
