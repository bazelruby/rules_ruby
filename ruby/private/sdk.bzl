load("@rules_ruby//ruby/private/toolchains:ruby_runtime.bzl", "ruby_runtime")
load(":constants.bzl", "RULES_RUBY_WORKSPACE_NAME", "get_supported_version")

def register_ruby_runtime(name, version = None):
    """Initializes a ruby toolchain at a specific version.

    A special version "system" or "system_ruby" will use whatever version of
    ruby is installed on the host system.  Besides that, this rules supports all
    of versions in the SUPPORTED_VERSIONS list.  The most recent matching
    version will beselected.

    If the current system ruby doesn't match a given version, it will be
    downloaded and built for use by the toolchain.  Toolchain selection occurs
    based on the //ruby/runtime:version flag setting.

    For example, `register_toolchains("ruby", "ruby-2.5")` will download and
    build the latest supported version of Ruby 2.5.
    By default, the system ruby will be used for all Bazel build and
    tests.  However, passing a flag such as:
        --@rules_ruby//ruby/runtime:version="ruby-2.5"
    will select the Ruby 2.5 installation.

    Optionally, a single string can be passed to this macro and it will use it
    for both the name and version.

    Args:
        name: the name of the generated Bazel repository
        version: a version identifier (e.g. system, ruby-2.5, jruby-9.2)
    """
    if not version:
        version = name
    if version == "system_ruby":
        # Special handling to give the system ruby repo a friendly name.
        version = "system"

    supported_version = get_supported_version(version)
    if supported_version.startswith("ruby-"):
        supported_version = supported_version[5:]

    ruby_runtime(
        name = name,
        version = supported_version,
    )

    if supported_version == "system":
        native.bind(
            name = "rules_ruby_system_jruby_implementation",
            actual = "@%s//:jruby_implementation" % name,
        )
        native.bind(
            name = "rules_ruby_system_ruby_implementation",
            actual = "@%s//:ruby_implementation" % name,
        )
        native.bind(
            name = "rules_ruby_system_no_implementation",
            actual = "@%s//:no_implementation" % name,
        )
        native.bind(
            name = "rules_ruby_system_interpreter",
            actual = "@%s//:ruby" % name,
        )
