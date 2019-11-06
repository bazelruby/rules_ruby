workspace(name = "com_github_yugui_rules_ruby")

load("@//ruby:deps.bzl", "ruby_register_toolchains", "ruby_rules_dependencies")

ruby_rules_dependencies()

ruby_register_toolchains()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

local_repository(
    name = "com_github_yugui_rules_ruby_ruby_tests_testdata_another_workspace",
    path = "ruby/tests/testdata/another_workspace",
)
