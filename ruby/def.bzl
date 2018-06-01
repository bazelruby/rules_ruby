# Repository rules
load(
    "@//ruby/toolchain:toolchains.bzl",
    _register_toolchains = "ruby_register_toolchains",
)

load(
    "@//ruby/private:library.bzl",
    _library = "ruby_library",
)

load(
    "@//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
)

ruby_register_toolchains = _register_toolchains
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
