# Ruby Constants
load(":providers.bzl", "RubyLibraryInfo")

RULES_RUBY_WORKSPACE_NAME = "@rules_ruby"
TOOLCHAIN_TYPE_NAME = "%s//ruby:toolchain_type" % RULES_RUBY_WORKSPACE_NAME

DEFAULT_BUNDLER_VERSION = "2.1.4"
DEFAULT_RSPEC_ARGS = {"--format": "documentation", "--force-color": None}
DEFAULT_RSPEC_GEMS = ["rspec", "rspec-its"]
DEFAULT_BUNDLE_NAME = "@bundle//"

BUNDLE_BIN_PATH = "bin"
BUNDLE_PATH = "lib"
BUNDLE_BINARY = "bundler/exe/bundler"

SCRIPT_INSTALL_GEM = "download_gem.rb"
SCRIPT_BUILD_FILE_GENERATOR = "create_bundle_build_file.rb"

RUBY_ATTRS = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
        providers = [RubyLibraryInfo],
    ),
    "includes": attr.string_list(),
    "rubyopt": attr.string_list(),
    "data": attr.label_list(
        allow_files = True,
    ),
    "main": attr.label(
        allow_single_file = True,
    ),
    "force_gem_pristine": attr.string_list(
        doc = "Jank hack. Run gem pristine on some gems that don't handle symlinks well",
    ),
    "_wrapper_template": attr.label(
        allow_single_file = True,
        default = "binary_wrapper.tpl",
    ),
    "_runner_template": attr.label(
        allow_single_file = True,
        default = "binary_runner.tpl",
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

RSPEC_ATTRS = {}

RSPEC_ATTRS.update(RUBY_ATTRS)
RSPEC_ATTRS.update(_RSPEC_ATTRS)

BUNDLE_ATTRS = {
    "gemfile": attr.label(
        allow_single_file = True,
        mandatory = True,
    ),
    "gemfile_lock": attr.label(
        allow_single_file = True,
    ),
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "vendor_cache": attr.bool(
        doc = "Symlink the vendor directory into the Bazel build space, this allows Bundler to access vendored Gems",
    ),
    "bundler_version": attr.string(
        default = DEFAULT_BUNDLER_VERSION,
    ),
    "includes": attr.string_list_dict(
        doc = "List of glob patterns per gem to be additionally loaded from the library",
    ),
    "excludes": attr.string_list_dict(
        doc = "List of glob patterns per gem to be excluded from the library",
    ),
    "_install_bundler": attr.label(
        default = "%s//ruby/private/bundle:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            SCRIPT_INSTALL_GEM,
        ),
        allow_single_file = True,
    ),
    "_create_bundle_build_file": attr.label(
        default = "%s//ruby/private/bundle:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            SCRIPT_BUILD_FILE_GENERATOR,
        ),
        doc = "Creates the BUILD file",
        allow_single_file = True,
    ),
}

GEMSPEC_ATTRS = {
    "gem_name": attr.string(),
    "gem_version": attr.string(default = "0.0.1"),
    "gem_summary": attr.string(),
    "gem_description": attr.string(),
    "gem_homepage": attr.string(),
    "gem_authors": attr.string_list(),
    "gem_author_emails": attr.string_list(),
    "gem_runtime_dependencies": attr.string_dict(
        allow_empty = True,
        doc = "Key value pairs of gem dependencies (name, version) where version can be None",
    ),
    "gem_development_dependencies": attr.string_dict(
        allow_empty = True,
        default = {
            "rspec": "",
            "rspec-its": "",
            "rubocop": "",
        },
        doc = "Key value pairs of gem dependencies (name, version) where version can be None",
    ),
    "srcs": attr.label_list(
        allow_files = True,
        default = [],
    ),
    "require_paths": attr.string_list(
        default = ["lib"],
    ),
    "deps": attr.label_list(
        allow_files = True,
    ),
    "data": attr.label_list(
        allow_files = True,
    ),
    "_gemspec_template": attr.label(
        allow_single_file = True,
        default = "%s//ruby/private/gemspec:gemspec_template.tpl" % RULES_RUBY_WORKSPACE_NAME,
    ),
    "_readme_template": attr.label(
        allow_single_file = True,
        default = "%s//ruby/private/gemspec:readme_template.tpl" % RULES_RUBY_WORKSPACE_NAME,
    ),
}

# The full list of supported pinned version numbers.
SUPPORTED_VERSIONS = [
    "system",
    "ruby-2.5.8",
    "ruby-2.5.9",
    "ruby-2.6.3",
    "ruby-2.6.4",
    "ruby-2.6.5",
    "ruby-2.6.6",
    "ruby-2.6.7",
    "ruby-2.6.8",
    "ruby-2.6.9",
    "ruby-2.7.1",
    "ruby-2.7.2",
    "ruby-2.7.3",
    "ruby-2.7.4",
    "ruby-2.7.5",
    "ruby-3.0.0",
    "ruby-3.0.1",
    "ruby-3.0.2",
    "ruby-3.0.3",
    "ruby-3.1.0",
    "ruby-3.1.1",
    "jruby-9.2.21.0",  # Corresponded to 2.5.8
    "jruby-9.3.6.0",  # Corresponds to 2.6.8
]

def get_supported_version(version):
    """Transforms a user-friendly version identifier to a full version number."""

    if version[0] >= "0" and version[1] <= "9":
        version = "ruby-" + version

    supported_version = None
    for v in sorted(SUPPORTED_VERSIONS, reverse = True):
        if v.startswith(version):
            supported_version = v
            break

    if not supported_version:
        fail("ruby_runtime: unsupported ruby version '%s' not in '%s'" % (version, SUPPORTED_VERSIONS))

    return supported_version
