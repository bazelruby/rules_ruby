load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "rb_library",
    "rb_toolchain",
)

package(default_visibility = ["//visibility:public"])

rb_toolchain(
    name = "ruby_host",
    interpreter = "//:ruby_bin",
    bundler = "//:bundler",
    rubyopt = [
        "-I$(RUNFILES_DIR)/org_ruby_lang_ruby_host/bundler/lib",
    ],
    runtime = "//:runtime",
    is_host = True,
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
    name = "bundler",
    srcs = ["bundler/exe/bundler"],
    data = glob(["bundler/**/*.rb"]),
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
