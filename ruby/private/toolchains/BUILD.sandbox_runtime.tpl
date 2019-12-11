load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)

package(default_visibility = ["//visibility:public"])

alias(
    name = "ruby_bin",
    actual = "@ruby_sandbox//:ruby",
)

alias(
    name = "bundler",
    actual = "@ruby_sandbox//:ruby",
)

ruby_toolchain(
    name = "toolchain",
    interpreter = "//:ruby_bin",
    bundler = "//:bundler",
    rubyopt = [
        "-I$(RUNFILES_DIR)/org_ruby_lang_ruby_toolchain/bundler/lib",
    ],
    runtime = "@org_ruby_lang_ruby_toolchain//:ruby_runtime_env",
    is_host = False,
    rules_ruby_workspace = "{rules_ruby_workspace}",
)

# vim: set ft=bzl :
