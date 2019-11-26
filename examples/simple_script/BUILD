package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_test",
)

ruby_binary(
    name = "default_bin",
    srcs = ["script.rb"],
    main = "script.rb",
    deps = [
        "//lib:foo",
        "@bundle//:libs",
    ],
)

ruby_test(
    name = "default_test",
    srcs = ["script_spec.rb"],
    main = "script_spec.rb",
    rubyopt = ["-rrspec/autorun"],  # require autorun because it is needed
    deps = [
        "//lib:foo",
        "@bundle//:libs",
    ],
)
