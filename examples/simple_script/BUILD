package(default_visibility = ["//:__subpackages__"])

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_test",
)
load(
    "@bazelruby_ruby_rules//ruby/private:rubocop.bzl",
    "ruby_rubocop",
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

ruby_rubocop(
    name = "rubocop",
    srcs = glob(
        ["**/*.rb"],
    ),
    autofix = True,
    rubocop_configs = [
        ":.relaxed-rubocop-2.4.yml",
        ":.rubocop.yml",
    ],
)

# # TODO: not the best way of defining this, should make `rubocop` rule like `buildifier`
# ruby_binary(
#     name = "rubocop",
#     srcs = [
#         ".relaxed-rubocop-2.4.yml",
#         ".rubocop.yml",
#         "script.rb",
#         "spec/script_spec.rb",
#         "@bundle//:bin/rubocop",
#     ],
#     args = [
#         "-c",
#         ".rubocop.yml",
#         "-P",
#         "-D",
#     ],
#     main = "@bundle//:bin/rubocop",
#     deps = [
#         "@bundle//:rubocop",
#     ],
# )
