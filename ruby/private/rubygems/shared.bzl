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
#     "GEM_ATTRS",
# )
load(
    "//ruby/private:constants.bzl",
    "RULES_RUBY_WORKSPACE_NAME",
)

DEFAULT_GEM_PATH = "vendor/bundle"
DEFAULT_BUNDLER_VERSION = "2.1.2"
TOOLS_RUBY_GEMSET = "lib/rules_ruby/gemset.rb"
TOOLS_RUBY_BUNDLE = "lib/rules_ruby/bundle.rb"
TOOLS_RUBY_SHARED = "lib/rules_ruby.rb"

TEMPLATE_GEM_AS_LIBRARY = "lib/BUILD.gem.library.tpl"
TEMPLATE_GEM_AS_BINARY = "lib/BUILD.gem.binary.tpl"
TEMPLATE_BUNDLER = "lib/BUILD.bundler.tpl"
TEMPLATE_BUILD_FILE_HEADER = "lib/BUILD.header.tpl"

RUBYGEMS_SOURCES = ["https://rubygems.org"]

GEM_ATTRS = {
    "ruby_sdk": attr.string(
        default = "@org_ruby_lang_ruby_toolchain",
    ),
    "ruby_interpreter": attr.label(
        default = "@org_ruby_lang_ruby_toolchain//:ruby",
    ),
    "rubygems_sources": attr.string_list(
        default = RUBYGEMS_SOURCES,
    ),
    "gems": attr.string_dict(
        mandatory = False,
    ),
    "gemfile": attr.label(
        allow_single_file = False,
    ),
    "gemfile_lock": attr.label(
        allow_single_file = True,
    ),
    "gem_home": attr.string(
        default = DEFAULT_GEM_PATH,
    ),
    "excludes": attr.string_list_dict(
        doc = "List of glob patterns per gem to be excluded from the library",
    ),
    # Tools (Internal)
    "_tools_gemset": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TOOLS_RUBY_GEMSET,
        ),
        allow_single_file = True,
    ),
    "_tools_shared": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TOOLS_RUBY_SHARED,
        ),
        doc = "Generates the BUILD file for the entire bundle",
        allow_single_file = True,
    ),
    "_tools_bundler": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TOOLS_RUBY_BUNDLE,
        ),
        doc = "Generates the BUILD file for the entire bundle",
        allow_single_file = True,
    ),
    # Templates
    "_template_gem_as_binary": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TEMPLATE_GEM_AS_BINARY,
        ),
        allow_single_file = True,
    ),
    "_template_gem_as_library": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TEMPLATE_GEM_AS_LIBRARY,
        ),
        allow_single_file = True,
    ),
    "_template_bundler": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TEMPLATE_BUNDLER,
        ),
        allow_single_file = True,
    ),
    "_template_build_header": attr.label(
        default = "%s//ruby/private/rubygems:%s" % (
            RULES_RUBY_WORKSPACE_NAME,
            TEMPLATE_BUILD_FILE_HEADER,
        ),
        allow_single_file = True,
    ),
}

def symlink_context(ctx):
    if ctx.attr.gemfile:
        ctx.symlink(ctx.attr.gemfile, "Gemfile")
        ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")

    ctx.symlink(ctx.attr._tools_bundler, TOOLS_RUBY_BUNDLE)
    ctx.symlink(ctx.attr._tools_shared, TOOLS_RUBY_SHARED)
    ctx.symlink(ctx.attr._tools_gemset, TOOLS_RUBY_GEMSET)

    ctx.symlink(ctx.attr._template_build_header, TEMPLATE_BUILD_FILE_HEADER)
    ctx.symlink(ctx.attr._template_bundler, TEMPLATE_BUNDLER)
    ctx.symlink(ctx.attr._template_gem_as_library, TEMPLATE_GEM_AS_LIBRARY)
    ctx.symlink(ctx.attr._template_gem_as_binary, TEMPLATE_GEM_AS_BINARY)

# Sets local bundler config values
def set_bundler_config(ctx, interpreter_path, environment, gem_home):
    print(">>> set_bundler_config() <<<")

    # Bundler is deprecating various flags in favor of the configuration.
    # HOWEVER — for reasons I can't explain, Bazel runs "bundle install" *prior*
    # to setting these flags. So the flags are then useless until we can force the
    # order and ensure that Bazel first downloads Bundler, then sets config, then
    # runs bundle install. Until then, it's a wild west out here.1
    #
    # Set local configuration options for bundler
    bundler_config = {
        "deployment": "'true'",
        "standalone": "'true'",
        "frozen": "'true'",
        "without": "development,test",
        "path": gem_home,
    }

    for option, value in [(option, value) for option, value in bundler_config.items()]:
        args = [
            "config",
            "--local",
            option,
            value,
        ]
        run_bundler(ctx, interpreter_path, environment, gem_home, args, True)

def run_bundler(ctx, interpreter, environment, gem_home, extra_args):
    print(">>> run_bundler({}) <<<".format(extra_args[0]))

    # Now we are running bundle install
    args = [
        interpreter,  # ruby
        "--enable=gems",  # bundler must run with rubygems enabled
        "-I",
        ".",
        "-I",  # Used to tell Ruby where to load the library scripts
        gem_home,  # Add vendor/bundle to the list of resolvers
        gem_home + "/exe/bundler",  # our binary
    ] + extra_args

    # print("running bundler with args\n", args)

    result = ctx.execute(
        args,
        quiet = False,
    )

    if result.return_code:
        print("bundler failed, args are: ", extra_args)
        fail(">>> run_bundler({}) FAILED with status %d:\nSTDOUT:\n%s\nSTDERR:\n%s\n".format(extra_args[0]) % (result.return_code, result.stdout, result.stderr))

def ruby_runtime_environment(gem_home):
    return {"RUBYOPT": "--enable=gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

def rubygems_sources_csv(rubygems_sources_list):
    # create a comma-separated string of rubygems sources
    sources = ""
    for source in rubygems_sources_list:
        if sources != "":
            sources += ","
        sources += source

    return sources
