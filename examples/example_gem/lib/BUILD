load(
    "@bazelrules_ruby_ruby//ruby:defs.bzl",
    "rb_library",
)

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "example_gem",
    srcs = ["example_gem.rb"],
    deps = ["//lib/foo:default_library"],
)
