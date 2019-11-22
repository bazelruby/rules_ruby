package(
    default_visibility = [
        "//apps/foo-bar/lib:__pkg__",
        "//apps/foo-bar/spec/foo:__pkg__",
    ],
)

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_library",
)

ruby_library(
    name = "bar",
    srcs = ["bar.rb"],
)

ruby_library(
    name = "version",
    srcs = ["version.rb"],
)
