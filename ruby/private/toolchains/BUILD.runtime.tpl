load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)

package(default_visibility = ["//visibility:public"])

ruby_toolchain(
    name = "toolchain",
    interpreter = "//:ruby_bin",
    runtime = "//:runtime",
    rules_ruby_workspace = "{rules_ruby_workspace}",
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
    static_library = {static_library},
    shared_library = {shared_library},
)

cc_library(
    name = "headers",
    includes = {includes},
    hdrs = glob({hdrs}),
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

# vim: set ft=bzl :
