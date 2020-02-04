package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "rb_gem",
)

rb_gem(
    name = "default_gem",
    authors = ["Coinbase"],
    gem_name = "example_gem",
    version = "0.1.0",
    deps = [
        "//lib:example_gem",
    ],
)
