workspace(name = "com_github_yugui_rules_ruby")

load("@//ruby:def.bzl", "ruby_register_toolchains")

ruby_register_toolchains()

load("@//ruby/private:bundle.bzl", "bundle_install")

bundle_install(
    name = "bundler_test",
    gemfile = "//:examples/Gemfile",
    gemfile_lock = "//:examples/Gemfile.lock",
    rules_ruby_workspace = "@",
)

local_repository(
    name = "com_github_yugui_rules_ruby_ruby_tests_testdata_another_workspace",
    path = "ruby/tests/testdata/another_workspace",
)
