load(
    "@com_github_yugui_rules_ruby//ruby/private:library.bzl",
    _library = "ruby_library",
)

load(
    "@com_github_yugui_rules_ruby//ruby/private:binary.bzl",
    _binary = "ruby_binary",
    _test = "ruby_test",
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
