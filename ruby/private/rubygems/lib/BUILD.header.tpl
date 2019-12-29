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
#
# FOR debugging the following are the expanded parameters:
#
# Attribute Map Global
#
# ruby_version   = {ruby_version}
# repo_name      = {repo_name}
# workspace_name = {workspace_name}
# bundle_path    = {bundle_path}
# gem_prefix     = {gem_prefix}
# rubyopts       = {rubyopts}
#
#—————————————————————————————————————————————————————————————————————————————————

load(
    "{workspace_name}//ruby:defs.bzl",
    "ruby_binary",
    "ruby_library",
    "ruby_test",
)

package(default_visibility = ["//visibility:public"])
