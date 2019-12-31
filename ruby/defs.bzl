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
    "@bazelruby_ruby_rules//ruby/private:bundle.bzl",
    _ruby_bundle = "ruby_bundle",
)

ruby_toolchain = _toolchain
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
bundle_install = _ruby_bundle
ruby_bundle = _ruby_bundle
