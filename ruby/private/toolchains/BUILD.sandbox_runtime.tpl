load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)

package(default_visibility = ["//visibility:public"])

ruby_toolchain(
    name = "toolchain",
    interpreter = "@ruby_sandbox//:ruby",
    runtime = "@ruby_sandbox//:ruby_runtime_env",
    is_host = False,
    rules_ruby_workspace = "{rules_ruby_workspace}",
)

sh_binary(
    name = "ruby",
    srcs = ["@ruby_sandbox//:ruby.sh"],
    data = ["@ruby_sandbox//:ruby_runtime_env"],
)

# vim: set ft=bzl :
