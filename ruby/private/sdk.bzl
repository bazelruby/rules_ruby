load("@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl", "ruby_runtime")
load (":constants.bzl", "SUPPORTED_VERSIONS")

def register_ruby_toolchain(name, version = "system"):
    """Registers ruby toolchains in the WORKSPACE file."""

    for v in sorted(SUPPORTED_VERSIONS, reverse=True):
        if v.startswith(version):
            supported_version = v
            break

    if not supported_version:
        fail("register_ruby_toolchain: unsupported ruby version '%s' not in '%s'" % (version, SUPPORTED_VERSIONS))

    ruby_runtime(
        name = name,
        version = supported_version,
    )

    native.register_toolchains(
        "@%s//:toolchain" % name,
    )

    # Bind the system ruby rules that we need internally.
    if version == "system":
        native.bind(
            name = "rules_ruby_system_jruby_implementation",
            actual = "@%s//:jruby_implementation" % name
        )
        native.bind(
            name = "rules_ruby_system_interpreter",
            actual = "@%s//:ruby" % name
        )
