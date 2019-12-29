# buildifier_disable=reformat

RULES_RUBY_WORKSPACE_NAME    = "@bazelruby_ruby_rules"
TOOLCHAIN_TYPE_NAME = "%s//ruby:toolchain_type" % RULES_RUBY_WORKSPACE_NAME

DEFAULT_GEM_PATH = "vendor/bundle"

TOOLS_RUBY_GEMSET = "lib/rules_ruby/gemset.rb"
TOOLS_RUBY_BUNDLE = "lib/rules_ruby/bundle.rb"
TOOLS_RUBY_SHARED = "lib/rules_ruby.rb"

TEMPLATE_GEM_AS_LIBRARY = "lib/BUILD.gem.library.tpl"
TEMPLATE_GEM_AS_BINARY = "lib/BUILD.gem.binary.tpl"
TEMPLATE_BUNDLER = "lib/BUILD.bundler.tpl"
TEMPLATE_BUILD_FILE_HEADER = "lib/BUILD.header.tpl"

RUBYGEMS_SOURCES = ["https://rubygems.org"]

# Grab this for the files that need these constants,
# Buildifier will remove the ones you don't use.
# load(
#     "//ruby/private:constants.bzl",
#     "RULES_RUBY_WORKSPACE_NAME",
#     "TOOLCHAIN_TYPE_NAME",
#     "DEFAULT_GEM_PATH",
#     "TOOLS_RUBY_GEMSET",
#     "TOOLS_RUBY_BUNDLE",
#     "TOOLS_RUBY_SHARED",
#     "TEMPLATE_GEM_AS_LIBRARY",
#     "TEMPLATE_GEM_AS_BINARY",
#     "TEMPLATE_BUNDLER",
#     "TEMPLATE_BUILD_FILE_HEADER",
#     "RUBYGEMS_SOURCES",
# )
