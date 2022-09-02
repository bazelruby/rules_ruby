load(
    "@rules_ruby//ruby:defs.bzl",
    "ruby_library",
)

package(default_visibility = ["//:__subpackages__"])

ruby_library(
    name = "example_gem",
    srcs = ["example_gem.rb"],
    deps = ["//lib/foo:default_library"],
)
