package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_library",
    "ruby_test",
)

ruby_library(
    name = "script.lib",
    srcs = [
        "script.rb",
        "//lib:foo",
    ],
    deps = [
        "@bundle//:awesome_print",
        "@bundle//:colored2",
    ],
)

ruby_binary(
    name = "bin",
    srcs = ["script.rb"],
    main = "script.rb",
    deps = [
        ":script.lib",
        "//lib:foo",
        "@bundle//:awesome_print",
        "@bundle//:colored2",
    ],
)

ruby_test(
    name = "rspec",
    timeout = "short",
    srcs = [
        "script.rb",
        "spec/lib/foo_spec.rb",
        "spec/script_spec.rb",
        "spec/spec_helper.rb",
        "@bundle//:bin/rspec",
    ],
    args = [
        "spec",
    ],
    includes = [
        ".",
        "lib",
        "spec",
    ],
    main = "spec/spec_helper.rb",
    deps = [
        "//lib:foo",
        "@bundle//:awesome_print",
        "@bundle//:colored2",
        "@bundle//:rspec",
        "@bundle//:rspec-its",
    ],
)

# TODO: not the best way of defining this, should make `rubocop` rule like `buildifier`
ruby_binary(
    name = "rubocop",
    srcs = [
        ".relaxed-rubocop-2.4.yml",
        ".rubocop.yml",
        "script.rb",
        "spec/lib/foo_spec.rb",
        "spec/script_spec.rb",
        "spec/spec_helper.rb",
        "@bundle//:bin/rubocop",
    ],
    args = [
        "-c",
        ".rubocop.yml",
        "-P",
        "-D",
    ],
    main = "@bundle//:bin/rubocop",
    deps = [
        "//lib:foo",
        "@bundle//:rubocop",
    ],
)
