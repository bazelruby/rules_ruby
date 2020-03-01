load(
    "@bazelruby_rules_ruby//ruby/private:toolchain.bzl",
    _toolchain = "ruby_toolchain",
)
load(
    "@bazelruby_rules_ruby//ruby/private:library.bzl",
    _library = "ruby_library",
)
load(
    "@bazelruby_rules_ruby//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
)
load(
    "@bazelruby_rules_ruby//ruby/private/bundle:def.bzl",
    _bundle = "bundle_install",
    _ruby_bundle = "ruby_bundle_install",
)
load(
    "@bazelruby_rules_ruby//ruby/private:rspec.bzl",
    _rspec = "ruby_rspec",
    _rspec_test = "ruby_rspec_test",
)
load(
    "@bazelruby_rules_ruby//ruby/private/rubocop:def.bzl",
    _rubocop = "rubocop",
)
load(
    "@bazelruby_rules_ruby//ruby/private/gemspec:def.bzl",
    _gem = "gem",
    _gemspec = "gemspec",
)

ruby_toolchain = _toolchain
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
ruby_rspec_test = _rspec_test
ruby_rspec = _rspec
ruby_bundle = _ruby_bundle
ruby_bundle_install = _bundle
ruby_rubocop = _rubocop
ruby_gemspec = _gemspec
ruby_gem = _gem
