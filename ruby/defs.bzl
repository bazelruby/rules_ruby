load(
    "@rules_ruby//ruby/private:toolchain.bzl",
    _mock_toolchain = "mock_ruby_toolchain",
    _toolchain = "ruby_toolchain",
)
load(
    "@rules_ruby//ruby/private:library.bzl",
    _library = "ruby_library",
)
load(
    "@rules_ruby//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
)
load(
    "@rules_ruby//ruby/private/bundle:def.bzl",
    _bundle_install = "bundle_install",
)
load(
    "@rules_ruby//ruby/private:rspec.bzl",
    _rspec = "ruby_rspec",
    _rspec_test = "ruby_rspec_test",
)
load(
    "@rules_ruby//ruby/private/rubocop:def.bzl",
    _rubocop = "rubocop",
)
load(
    "@rules_ruby//ruby/private/gemspec:def.bzl",
    _gem = "gem",
    _gemspec = "gemspec",
)
load(
    "@rules_ruby//ruby/private:sdk.bzl",
    _register_ruby_runtime = "register_ruby_runtime",
)

ruby_mock_toolchain = _mock_toolchain
ruby_toolchain = _toolchain
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
ruby_rspec_test = _rspec_test
ruby_rspec = _rspec
ruby_bundle_install = _bundle_install
ruby_rubocop = _rubocop
ruby_gemspec = _gemspec
ruby_gem = _gem
ruby_runtime = _register_ruby_runtime
