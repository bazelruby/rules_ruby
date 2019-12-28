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
    "@bazelruby_ruby_rules//ruby/private/bundle:bundle.bzl",
    _bundle_install = "ruby_bundle_install",
)
load(
    "@bazelruby_ruby_rules//ruby/private/bundle:gems.bzl",
    _gems_install = "ruby_gems_install",
)

ruby_binary = _binary
ruby_bundle_install = _bundle_install
ruby_gems_install = _gems_install
ruby_library = _library
ruby_test = _test
ruby_toolchain = _toolchain
