# Repository rules
load(
    "@com_github_yugui_rules_ruby//ruby/toolchain:toolchains.bzl",
    "ruby_register_toolchains",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:library.bzl",
    "ruby_library",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:binary.bzl",
    "ruby_binary",
)
