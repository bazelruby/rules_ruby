load(
    "@bazelrules_ruby_ruby//ruby:defs.bzl",
    "rb_gem",
)

package(default_visibility = ["//:__subpackages__"])

rb_gem(
    name = "default_gem",
    authors = ["Coinbase"],
    gem_name = "example_gem",
    version = "0.1.0",
    deps = [
        "//lib:example_gem",
    ],
)
