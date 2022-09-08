load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

package(default_visibility = ["//visibility:public"])

ruby_toolchain(
    name = "toolchain",
    interpreter = "//:ruby_bin",
    rules_ruby_workspace = "{rules_ruby_workspace}",
    runtime = "//:runtime",
    headers = "//:headers",
    target_settings = [
        "{rules_ruby_workspace}//ruby/runtime:{setting}"
    ],
    # TODO(yugui) Extract platform info from RbConfig
    # exec_compatible_with = [],
    # target_compatible_with = [],
)

sh_binary(
    name = "ruby_bin",
    srcs = ["ruby"],
    data = [":runtime"],
)

cc_import(
    name = "libruby",
    hdrs = glob({hdrs}),
    shared_library = {shared_library},
    static_library = {static_library},
)

cc_library(
    name = "headers",
    hdrs = glob({hdrs}),
    includes = {includes},
)

filegroup(
    name = "runtime",
    srcs = glob(
        include = ["**/*"],
        exclude = [
            "BUILD.bazel",
            "WORKSPACE",
        ],
    ),
)

# Provide config settings to signal the ruby platform to downstream code.
# This should never be overridden, and is determined automatically during the
# creation of the toolchain.
string_flag(
    name = "internal_ruby_implementation",
    build_setting_default = "{implementation}",
    values = [
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

# vim: set ft=bzl :
