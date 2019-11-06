load(
    "@com_github_yugui_rules_ruby//ruby/private:toolchain.bzl",
    _toolchain = "ruby_toolchain",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:library.bzl",
    _library = "ruby_library",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:bundle.bzl",
    _bundle_install = "bundle_install",
)

ruby_toolchain = _toolchain
ruby_library = _library
ruby_binary = _binary
ruby_test = _test
bundle_install = _bundle_install
