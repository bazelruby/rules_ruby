
load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)




###
# Toolchain
###

ruby_toolchain(
    name = "ruby_host",
    interpreter = "@ruby_2_6_3//:ruby",
    bundler = "//:bundler",
    init_files = ["//:init_loadpath"],
    rubyopt = [
        "-I../org_ruby_lang_ruby_host/bundler/lib",
    ],
    runtime = "//:runtime",
    rules_ruby_workspace = "{rules_ruby_workspace}",
    # TODO(yugui) Extract platform info from RbConfig
    # exec_compatible_with = [],
    # target_compatible_with = [],
)