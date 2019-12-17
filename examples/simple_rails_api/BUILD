package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_test",
)

ruby_binary(
    name = "server",
    srcs = glob(
        include = [
            "app/**/*",
            "config/**/*",
            "bin/*",
            "config.ru",
            "Gemfile",
            "Gemfile.lock",
        ],
    ),
    main = ":bin/rails",
    deps = [
        "@bundle//:rails",
    ],
)

ruby_test(
    name = "script_spec",
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
