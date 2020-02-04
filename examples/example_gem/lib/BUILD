package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "rb_library",
)

rb_library(
    name = "example_gem",
    srcs = ["example_gem.rb"],
    deps = ["//lib/foo:default_library"],
)
