load(
    "@bazelruby_ruby_rules//ruby/private:toolchain.bzl",
    _toolchain = "rb_toolchain",
)
load(
    "@bazelruby_ruby_rules//ruby/private:library.bzl",
    _library = "rb_library",
)
load(
    "@bazelruby_ruby_rules//ruby/private:binary.bzl",
    _binary = "rb_binary",
    _test = "rb_test",
)
load(
    "@bazelruby_ruby_rules//ruby/private:bundle.bzl",
    _bundle_install = "bundle_install",
)

rb_toolchain = _toolchain
rb_library = _library
rb_binary = _binary
rb_test = _test
bundle_install = _bundle_install

# Aliases for backward compatibility
ruby_toolchain = _toolchain
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
