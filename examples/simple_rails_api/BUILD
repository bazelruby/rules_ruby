load(
    "@rules_ruby//ruby:defs.bzl",
    "ruby_binary",
)

package(default_visibility = ["//:__subpackages__"])

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
