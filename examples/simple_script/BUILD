package(default_visibility = ["//:__subpackages__"])

# load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")
load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_library",
    "ruby_test",
)

filegroup(
    name = "simple-script.sources",
    srcs = [
        ".rubocop.yml",
        "Gemfile",
        "Gemfile.lock",
        "exe/simple-script",
        "lib/foo/foo.rb",
        "lib/simple_script.rb",
        "spec/lib/foo/foo_spec.rb",
        "spec/lib/simple_script_spec.rb",
        "spec/spec_helper.rb",
    ],
)

filegroup(
    name = "simple-script.deps",
    srcs = [
        "@bundle//:awesome_print",
        "@bundle//:rspec",
    ],
)

ruby_library(
    name = "simple-script.lib",
    srcs = [
        ":simple-script.sources",
    ],
    deps = [
        "@bundle//:awesome_print",
        "@bundle//:rspec",
    ],
)

pkg_tar(
    name = "simple-script-tar",
    srcs = [
        ":simple-script.sources",
    ],
    mode = "0755",
)

ruby_binary(
    name = "simple-script.exe",
    srcs = ["exe/simple-script"],
    main = "exe/simple-script",
    deps = [
        ":simple-script.lib",
        "@bundle//:awesome_print",
    ],
)

ruby_test(
    name = "simple-script.spec",
    timeout = "short",
    srcs = [
        "lib/foo/foo.rb",
        "lib/simple_script.rb",
        "spec/lib/foo/foo_spec.rb",
        "spec/lib/simple_script_spec.rb",
        "spec/spec_helper.rb",
    ],
    args = [
        "spec",
    ],
    main = "spec/spec_helper.rb",
    rubyopt = ["-rrspec/autorun"],
    deps = [
        "@bundle//:rspec",
    ],
)

# ruby_binary(
#     name = "simple-script.rubocop",
#     srcs = [
#         ".relaxed-rubocop-2.4.yml",
#         ".rubocop.yml",
#         "lib/foo/foo.rb",
#         "lib/simple_script.rb",
#         "spec/lib/foo/foo_spec.rb",
#         "spec/lib/simple_script_spec.rb",
#         "spec/spec_helper.rb",
#     ],
#     args = [
#         "-c",
#         ".rubocop.yml",
#         "-c",
#         ".relaxed-rubocop-2.4.yml",
#         "-P",
#         "-D",
#     ],
#     data = [":simple-script.sources"],
#     main = "@bundle/bin/rubocop",
#     deps = [
#         ":simple-script.lib",
#         "@bundle//:rubocop",
#     ],
# )
