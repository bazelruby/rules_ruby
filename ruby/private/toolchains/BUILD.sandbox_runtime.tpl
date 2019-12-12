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
    is_host = False,
    rules_ruby_workspace = "{rules_ruby_workspace}",
)

sh_binary(
    name = "ruby_bin",
    srcs = [":build/bin/ruby"],
    data = [":runtime"],
)

filegroup(
    name = "runtime",
    srcs = glob(
        include = ["build/**/*"],
    ),
)

# vim: set ft=bzl :