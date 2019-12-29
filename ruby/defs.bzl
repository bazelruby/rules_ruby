load(
    "@bazelruby_ruby_rules//ruby/private:toolchain.bzl",
    _toolchain = "ruby_toolchain",
)
load(
    "@bazelruby_ruby_rules//ruby/private:library.bzl",
    _library = "ruby_library",
)
load(
    "@bazelruby_ruby_rules//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
)
load(
    "@bazelruby_ruby_rules//ruby/private/rubygems:bundle.bzl",
    _bundle = "ruby_bundle",
    _gemset = "ruby_gemset",
)

ruby_binary = _binary
ruby_bundle = _bundle
ruby_gemset = _gemset
ruby_library = _library
ruby_test = _test
ruby_toolchain = _toolchain
