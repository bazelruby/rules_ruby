load(
    "@bazelruby_ruby_rules//ruby/private:library.bzl",
    _library = "rb_library",
)
load(
    "@bazelruby_ruby_rules//ruby/private:binary.bzl",
    _binary = "rb_binary",
    _test = "rb_test",
)

def ruby_library(**attrs):
    print("//ruby:def.bzl was deprecated and will be removed soon. Use //ruby:defs.bzl instead")
    _library(**attrs)

def ruby_binary(**attrs):
    print("//ruby:def.bzl was deprecated and will be removed soon. Use //ruby:defs.bzl instead")
    _binary(**attrs)

def ruby_test(**attrs):
    print("//ruby:def.bzl was deprecated and will be removed soon. Use //ruby:defs.bzl instead")
    _test(**attrs)
