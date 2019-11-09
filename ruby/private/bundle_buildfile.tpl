load(
  "@rules_ruby//ruby:def.bzl",
  "rb_library",
)

package(default_visibility = ["//visibility:public"])

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":libs"],
)

rb_library(
  name = "libs",
  srcs = glob(
    include = [
      # TODO Support other ruby engines
      # TODO Fix the ruby_version with the given interpter.
      "lib/ruby/*/gems/*/**/*",
      "lib/ruby/*/bin/**/*",
    ],
    exclude = {exclude},
  ),
  deps = [":bundler_setup"],
  rubyopt = ["-r../{repo_name}/lib/bundler/setup.rb"],
)

rb_library(
  name = "bundler_setup",
  srcs = ["lib/bundler/setup.rb"],
  visibility = ["//visibility:private"],
)

# vim: set ft=bzl :
