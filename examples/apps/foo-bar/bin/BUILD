load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
)

ruby_binary(
    name = "show_version",
    srcs = ["show_version.rb"],
    deps = [
        "//apps/foo-bar/lib:foo",
    ],
)

sh_test(
    name = "show_version_test",
    srcs = [":show_version"],
)
