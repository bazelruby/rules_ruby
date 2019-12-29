load(
    "//ruby/private:constants.bzl",
    "DEFAULT_GEM_PATH",
    "RUBYGEMS_SOURCES",
    "RULES_RUBY_WORKSPACE_NAME",
    "TEMPLATE_GEM_AS_BINARY",
    "TEMPLATE_GEM_AS_LIBRARY",
    "TOOLS_RUBY_GEMSET",
    "TOOLS_RUBY_SHARED",
)

# Installs arbitrary gem/version combo to any location specified by gem_home
# The tool used here is lib/rules_ruby/gemset.rb
def install_gem(
        ctx,
        interpreter,
        gem_name,
        gem_version,
        gem_home = DEFAULT_GEM_PATH,
        environment = {}):
    args = [
        interpreter,
        TOOLS_RUBY_GEMSET,
        gem_name + ":" + gem_version,
        "-g",
        gem_home,
        "-p",
        "-d",
    ]

    result = ctx.execute(
        args,
        environment = environment,
    )

    print(result.stdout)

    if result.return_code:
        message = "Failed to evaluate ruby snippet with {}: {}".format(
            interpreter,
            result.stderr,
        )
        fail(message)

def _ruby_gemset(ctx):
    ctx.symlink(ctx.attr._tools_gemset, TOOLS_RUBY_GEMSET)
    ctx.symlink(ctx.attr._tools_shared, TOOLS_RUBY_SHARED)
    ctx.symlink(ctx.attr._template_gem_as_library, TEMPLATE_GEM_AS_LIBRARY)
    ctx.symlink(ctx.attr._template_gem_as_binary, TEMPLATE_GEM_AS_BINARY)

    repo = ctx.attr.name
    gems = ctx.attr.gems
    gem_home = repo + "/" + ctx.attr.gem_home
    rubygems_sources = ctx.attr.rubygems_sources
    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

    for gem_name, gem_version in [(gem_name, gem_version) for gem_name, gem_version in ctx.attr.gems.items()]:
        result = install_gem(
            ctx,
            interpreter_path,
            gem_name,
            gem_version,
            gem_home,
            environment,
        )

        if result.return_code:
            fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))
        else:
            print("Gem %s (%s) installed successfully" % (gem_name, gem_version))

ruby_gemset = repository_rule(
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_toolchain",
        ),
        "ruby_interpreter": attr.label(
            default = "@org_ruby_lang_ruby_toolchain//:ruby",
        ),
        "gems": attr.string_dict(
            mandatory = True,
        ),
        "gem_home": attr.string(
            default = DEFAULT_GEM_PATH,
            doc = "Relative path for GEM_HOME where bundler installs gems. Can be '.' or eg 'vendor/bundle'",
        ),
        "rubygems_sources": attr.string_list(
            default = RUBYGEMS_SOURCES,
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),
        "_tools_ruby_gemset": attr.label(
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
    },
    implementation = _ruby_gemset,
)
