workspace(name = "com_github_yugui_rules_ruby")

load("@com_github_yugui_rules_ruby//ruby:def.bzl", "ruby_register_toolchains")

ruby_register_toolchains()

load("@com_github_yugui_rules_ruby//ruby/private:bundle.bzl", "bundle_install")

bundle_install(
    name = "bundler_test",
    gemfile = "//:examples/Gemfile",
    gemfile_lock = "//:examples/Gemfile.lock",
)
