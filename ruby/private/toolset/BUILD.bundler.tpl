#—————————————————————————————————————————————————————————————————————————————————
# WARNING: this file is auto-generated and will be replaced every repository rule
# is run.
#
# © 2018-2020 Yuki (@yugui) Sonoda,
#             Graham Jenson,
#             Konstantin Gredeskoul
#             & BazelRuby authors
#
# Distributed under Apache 2.0 LICENSE.
#
#—————————————————————————————————————————————————————————————————————————————————
#
# LIBRARY HEADER with BUNDLER DEFINITIONS
#
#—————————————————————————————————————————————————————————————————————————————————

load(
  "{workspace_name}//ruby:defs.bzl",
  "ruby_library",
  "ruby_binary",
  "ruby_test",
)

package(default_visibility = ["//visibility:public"])

ruby_library(
  name = "{repo_name}-libs",
  srcs = glob(
     ["{bundle_path}/{gem_path}/*/lib/**/*"]
  ),
  visibility = ["//visibility:public"],
  deps = [":bundler_setup"],
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/lib/bundler/setup.rb"],
)

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":{repo_name}-libs"],
)

ruby_library(
  name = "bundler_setup",
  srcs = ["{bundle_path}/lib/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

ruby_library(
  name = "bundler",
  srcs = glob(
    [
      "bundler/**/*",
    ],
  ),
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/lib/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

#—————————————————————————————————————————————————————————————————————————————————
# Filegroup that includes all *.gemspec files
#
filegroup(
  name = "{repo_name}.gemspec",
  srcs = glob(
    include = [
      "{gem_path}/**/{name}.gemspec",
    ],
  ),
  visibility = ["//visibility:public"],
)

