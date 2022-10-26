load("@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl", "ruby_runtime")
load(":constants.bzl", "get_supported_version")

def _register_toolchain(version):
    """Registers ruby toolchains in the WORKSPACE file."""
    name = "local_config_ruby_%s" % version

    supported_version = get_supported_version(version)
    if supported_version.startswith("ruby-"):
        supported_version = supported_version[5:]

    ruby_runtime(
        name = name,
        version = supported_version,
    )

    native.register_toolchains(
        "@%s//:toolchain" % name,
    )

def rules_ruby_register_toolchains(versions = []):
    """Initializes ruby toolchains at different supported versions.

    A special version "system" will use whatever version of ruby is installed
    on the host system.  Besides that, this rules supports all of versions in
    the SUPPORTED_VERSIONS list.  The most recent matching version will be
    selected.

    If the current system ruby doesn't match a given version, it will be
    downloaded and built for use by the toolchain.  Toolchain selection occurs
    based on the //ruby/runtime:version flag setting.

    For example,
        rules_ruby_register_toolchains(["system", ruby-2.5", "jruby-9.2"])` will
    download and build the latest supported version of Ruby 2.5 and jruby 9.2.
    By default, the system ruby will be used for all Bazel build and
    tests.  However, passing a flag such as:
        --@rules_ruby//ruby/runtime:version="ruby-2.5"
    will select the Ruby 2.5 installation.

    Args:
      versions: a list of version identifiers
    """
    for version in versions:
        _register_toolchain(version)

    # Always provide a system toolchain for internal use.
    if not "system" in version:
        _register_toolchain("system")
    native.bind(
        name = "rules_ruby_system_jruby_implementation",
        actual = "@local_config_ruby_system//:jruby_implementation",
    )
    native.bind(
        name = "rules_ruby_system_interpreter",
        actual = "@local_config_ruby_system//:ruby",
    )
