package(default_visibility = ["//apps/foo-bar:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_library",
)

ruby_library(
    name = "foo",
    srcs = ["foo.rb"],
    includes = ["lib"],
    deps = [
        "//apps/foo-bar/lib/foo:bar",
        "//apps/foo-bar/lib/foo:version",
    ],
)
