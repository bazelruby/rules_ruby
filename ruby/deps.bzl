# Repository rules
load(
    "@bazelruby_ruby_rules//ruby/private:dependencies.bzl",
    _rules_dependencies = "rb_rules_dependencies",
)
load(
    "@bazelruby_ruby_rules//ruby/private:sdk.bzl",
    _register_toolchains = "rb_register_toolchains",
)

rb_rules_dependencies = _rules_dependencies
rb_register_toolchains = _register_toolchains

# Aliases for backward compatibility
ruby_rules_dependencies = _rules_dependencies
ruby_register_toolchains = _register_toolchains
