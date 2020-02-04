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
load(
    "@bazelruby_ruby_rules//ruby/private:rspec.bzl",
    _ruby_rspec = "ruby_rspec",
    _ruby_rspec_test = "ruby_rspec_test",
)
load(
    "@bazelruby_ruby_rules//ruby/private/rubocop:def.bzl",
    _rubocop = "rubocop",
)
load(
    "@bazelruby_ruby_rules//ruby/private:gemspec.bzl",
    _gemspec = "rb_gemspec",
)
load(
    "@bazelruby_ruby_rules//ruby/private:gem.bzl",
    _gem = "rb_gem",
)

ruby_toolchain = _toolchain

ruby_library = _library
ruby_binary = _binary
ruby_test = _test
ruby_rspec_test = _ruby_rspec_test
ruby_rspec = _ruby_rspec
ruby_bundle = _ruby_bundle
ruby_rubocop = _rubocop
ruby_gemspec = _gemspec
ruby_gem = _gem

rb_toolchain = _toolchain
rb_library = _library
rb_binary = _binary
rb_test = _test
rb_rspec = _ruby_rspec
rb_bundle = _ruby_bundle
rb_rubocop = _rubocop
rb_gemspec = _gemspec
rb_gem = _gem
