package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "rb_binary",
    "rb_test",
)

rb_binary(
    name = "default_bin",
    srcs = ["script.rb"],
    main = "script.rb",
    deps = [
        "//lib:foo",
        "@bundle//:libs",
    ],
)

rb_test(
    name = "script_spec",
    srcs = [
        "script.rb",
        "spec/script_spec.rb",
    ],
    main = "spec/script_spec.rb",
    rubyopt = ["-rrspec/autorun"],  # require autorun because it is needed
    deps = [
        "//lib:foo",
        "@bundle//:libs",
    ],
)
