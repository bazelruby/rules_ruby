package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_library",
    "ruby_test",
)

ruby_library(
    name = "simple-script-lib",
    srcs = [
        "exe/simple_script",
        "lib/foo/foo.rb",
        "lib/simple_script.rb",
    ],
)

# ruby_binary(
#     name = "simple-script-bin",
#     srcs = [":simple-script-lib"],
#     main = "//exe:simple_script",
#     deps = [
#         "//lib:simple-script",
#         "@bundle//:awesome_print",
#     ],
# )

ruby_test(
    name = "simple-script-spec",
    timeout = "short",
    srcs = [
        "spec/lib/foo/foo_spec.rb",
        "spec/lib/simple_script_spec.rb",
        "spec/spec_helper.rb",
    ],
    main = "spec/spec_helper.rb",
    rubyopt = ["-rrspec/autorun"],  # require autorun because it is needed
    deps = [
        ":simple-script-lib",
        "@bundle//:awesome_print",
        "@bundle//:rspec",
    ],
)

ruby_binary(
    name = "rubocop",
    srcs = [
        ".relaxed-rubocop-2.4.yml",
        ".rubocop.yml",
        "lib/foo/foo.rb",
        "lib/simple_script.rb",
        "spec/lib/foo/foo_spec.rb",
        "spec/lib/simple_script_spec.rb",
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
        "@bundle//:rubocop",
    ],
)
