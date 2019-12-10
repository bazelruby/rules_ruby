load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)

package(default_visibility = ["//visibility:public"])

ruby_toolchain(
    name = "ruby_26",
    interpreter = "@ruby_2_6_3//:ruby",
    bundler = "@ruby_2_6_3//:ruby",
    rubyopt = [
        "-I$(RUNFILES_DIR)/org_ruby_lang_ruby_26/bundler/lib",
    ],
    runtime = "//:runtime",
    is_host = False,
    rules_ruby_workspace = "{rules_ruby_workspace}",
)

# vim: set ft=bzl :
