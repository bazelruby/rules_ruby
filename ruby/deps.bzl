# Repository rules
load(
    "@bazelruby_ruby_rules//ruby/private:dependencies.bzl",
    _ruby_rules_dependencies = "ruby_rules_dependencies",
)
load(
    "@bazelruby_ruby_rules//ruby/private:sdk.bzl",
    _register_toolchains = "ruby_register_toolchains",
)

ruby_rules_dependencies = _ruby_rules_dependencies

ruby_register_toolchains = _register_toolchains
