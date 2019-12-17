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
        ],
    ),
    main = ":bin/rails",
    deps = [
        "@bundle//:rails",
    ],
)
