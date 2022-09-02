# Repository rules
load(
    "@rules_ruby//ruby/private:dependencies.bzl",
    _rules_ruby_dependencies = "rules_ruby_dependencies",
)
load(
    "@rules_ruby//ruby/private:sdk.bzl",
    _rules_ruby_select_sdk = "rules_ruby_select_sdk",
)

rules_ruby_dependencies = _rules_ruby_dependencies
rules_ruby_select_sdk = _rules_ruby_select_sdk
