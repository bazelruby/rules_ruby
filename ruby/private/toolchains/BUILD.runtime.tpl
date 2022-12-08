load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

package(default_visibility = ["//visibility:public"])

# Toolchain targets.  These will be mocked out with stubs if no ruby version
# can be found.
{toolchain}

# Provide config settings to signal the ruby platform to downstream code.
# This should never be overridden, and is determined automatically during the
# creation of the toolchain.
string_flag(
    name = "internal_ruby_implementation",
    build_setting_default = "{implementation}",
    values = [
        "none",
        "ruby",
        "jruby",
    ],
)

config_setting(
    name = "jruby_implementation",
    flag_values = {
        ":internal_ruby_implementation": "jruby",
    },
)

config_setting(
    name = "ruby_implementation",
    flag_values = {
        ":internal_ruby_implementation": "ruby",
    },
)

config_setting(
    name = "no_implementation",
    flag_values = {
        ":internal_ruby_implementation": "none",
    },
)

# vim: set ft=bzl :
