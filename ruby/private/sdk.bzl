load("@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl", "ruby_runtime")
load (":constants.bzl", "SUPPORTED_VERSIONS")

def _register_toolchain(version):
    """Registers ruby toolchains in the WORKSPACE file."""
    name = "local_config_ruby_%s" % version
    supported_version = None

    version = version.removeprefix("ruby-")
    for v in sorted(SUPPORTED_VERSIONS, reverse=True):
        if v.startswith(version):
            supported_version = v
            break

    if not supported_version:
        fail("rules_ruby_register_toolchains: unsupported ruby version '%s' not in '%s'" % (version, SUPPORTED_VERSIONS))

    ruby_runtime(
        name = name,
        version = supported_version,
    )

    native.register_toolchains(
        "@%s//:toolchain" % name,
    )

def rules_ruby_register_toolchains(version = None):
    _register_toolchain("system")
    if version != "system":
        if version:
            _register_toolchain(version)
        else:
            _register_toolchain("2.5")
            _register_toolchain("2.6")
            _register_toolchain("2.7")
            _register_toolchain("3.0")
            _register_toolchain("3.1")
            _register_toolchain("jruby-9.2")
            _register_toolchain("jruby-9.3")

    native.bind(
        name = "rules_ruby_system_jruby_implementation",
        actual = "@local_config_ruby_system//:jruby_implementation"
    )
    native.bind(
        name = "rules_ruby_system_interpreter",
        actual = "@local_config_ruby_system//:ruby"
    )
