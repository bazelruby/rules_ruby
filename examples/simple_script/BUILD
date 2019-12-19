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
        "@bundle//:awesome_print",
    ],
)

ruby_test(
    name = "script_spec",
    timeout = "short",
    srcs = [
        "script.rb",
        "spec/script_spec.rb",
    ],
    main = "spec/script_spec.rb",
    rubyopt = ["-rrspec/autorun"],  # require autorun because it is needed
    deps = [
        "//lib:foo",
        "@bundle//:awesome_print",
        "@bundle//:rspec",
    ],
)

# TODO: not the best way of defining this, should make `rubocop` rule like `buildifier`
ruby_binary(
    name = "rubocop",
    srcs = [
        ".rubocop.yml",
        "script.rb",
        "spec/script_spec.rb",
        "@bundle//:bin/rubocop",
    ],
    args = [
        "-P",
        "-D",
    ],
    main = "@bundle//:bin/rubocop",
    deps = [
        "@bundle//:relaxed-rubocop",
        "@bundle//:rubocop",
    ],
)
