load(":providers.bzl", "RubyLibrary")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

RULES_RUBY_WORKSPACE_NAME = "@bazelruby_ruby_rules"
TOOLCHAIN_TYPE_NAME = "%s//ruby:toolchain_type" % RULES_RUBY_WORKSPACE_NAME

DEFAULT_BUNDLER_VERSION = "2.1.2"
DEFAULT_RSPEC_ARGS = {"--format": "documentation", "--force-color": None}
DEFAULT_RSPEC_GEMS = ["rspec", "rspec-its"]
DEFAULT_BUNDLE_NAME = "@bundle//"

RUBY_ATTRS = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
        providers = [RubyLibrary],
    ),
    "includes": attr.string_list(),
    "rubyopt": attr.string_list(),
    "data": attr.label_list(
        allow_files = True,
    ),
    "main": attr.label(
        allow_single_file = True,
    ),
    "_wrapper_template": attr.label(
        allow_single_file = True,
        default = "binary_wrapper.tpl",
    ),
    "_misc_deps": attr.label_list(
        allow_files = True,
        default = ["@bazel_tools//tools/bash/runfiles"],
    ),
}

_RSPEC_ATTRS = {
    "bundle": attr.string(
        default = DEFAULT_BUNDLE_NAME,
        doc = "Name of the bundle where the rspec gem can be found, eg @bundle//",
    ),
    "rspec_args": attr.string_list(
        default = [],
        doc = "Arguments passed to rspec executable",
    ),
    "rspec_executable": attr.label(
        default = "%s:bin/rspec" % (DEFAULT_BUNDLE_NAME),
        allow_single_file = True,
        doc = "RSpec Executable Label",
    ),
}

RSPEC_ATTRS = dicts.add(RUBY_ATTRS, _RSPEC_ATTRS)

BUNDLE_ATTRS = {
    "ruby_sdk": attr.string(
        default = "@org_ruby_lang_ruby_toolchain",
    ),
    "ruby_interpreter": attr.label(
        default = "@org_ruby_lang_ruby_toolchain//:ruby",
    ),
    "gemfile": attr.label(
        allow_single_file = True,
        mandatory = True,
    ),
    "gemfile_lock": attr.label(
        allow_single_file = True,
    ),
    "version": attr.string(
        mandatory = False,
    ),
    "bundler_version": attr.string(
        default = DEFAULT_BUNDLER_VERSION,
    ),
    "gemspec": attr.label(
        allow_single_file = True,
    ),
    "excludes": attr.string_list_dict(
        doc = "List of glob patterns per gem to be excluded from the library",
    ),
    "_install_bundler": attr.label(
        default = "%s//ruby/private/bundle:install_bundler.rb" % (
            RULES_RUBY_WORKSPACE_NAME
        ),
        allow_single_file = True,
    ),
    "_create_bundle_build_file": attr.label(
        default = "%s//ruby/private/bundle:create_bundle_build_file.rb" % (
            RULES_RUBY_WORKSPACE_NAME
        ),
        doc = "Creates the BUILD file",
        allow_single_file = True,
    ),
}
