load(
    "//ruby/private:constants.bzl",
    "BUNDLE_DEFAULT_DESTINATION",
    "RULES_RUBY_WORKSPACE_NAME",
)

# Installs arbitrary gem/version combo to any location specified by gem_home
# The tool used here is ruby_install_gem.rb
def install_gem(
        ctx,
        interpreter,
        gem_name,
        gem_version,
        gem_home = BUNDLE_DEFAULT_DESTINATION):
    args = [
        interpreter,
        "ruby_install_gem.rb",
        "-n",
        gem_name,
        "-v",
        gem_version,
        "-g",
        gem_home,
    ]

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

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

def install_bundler(ctx, interpreter, bundler_version, gem_home):
    return install_gem(ctx, interpreter, "bundler", bundler_version, gem_home)

def _ruby_install_gems(ctx):
    ctx.symlink(ctx.attr._ruby_install_gem, "ruby_install_gem.rb")
    ctx.symlink(ctx.attr._ruby_helpers, "ruby_helpers.rb")
    ctx.symlink(ctx.attr._build_gem_library_template, "BUILD.gem.library.tpl")
    ctx.symlink(ctx.attr._build_gem_binary_template, "BUILD.gem.binary.tpl")

    gems = ctx.attr.gems
    gem_home = ctx.attr.gem_home
    rubygems_sources = ctx.attr.rubygems_sources
    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

    for gem_name, gem_version in [(gem_name, gem_version) for gem_name, gem_version in gems()]:
        result = install_gem(
            ctx,
            interpreter_path,
            gem_name,
            gem_version,
            gem_home,
        )

        if result.return_code:
            fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))

ruby_gems_install = repository_rule(
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_toolchain",
        ),
        "ruby_interpreter": attr.label(
            default = "@org_ruby_lang_ruby_toolchain//:ruby",
        ),
        "gems": attr.string_list_dict(
            default = {},
            mandatory = True,
        ),
        "gem_home": attr.string(
            default = BUNDLE_DEFAULT_DESTINATION,
            doc = "Relative path for GEM_HOME where bundler installs gems. Can be '.' or eg 'vendor/bundle'",
        ),
        "rubygems_sources": attr.string_list(
            default = ["https://rubygems.org"],
            mandatory = True,
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),
        "_ruby_install_gem": attr.label(
            default = "%s//ruby/private/toolset:ruby_install_gem.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_ruby_helpers": attr.label(
            default = "%s//ruby/private/toolset:ruby_helpers.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "Generates the BUILD file for the entire bundle",
            allow_single_file = True,
        ),
        "_build_gem_binary_template": attr.label(
            default = "%s//ruby/private/toolset:BUILD.gem.binary.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_build_gem_library_template": attr.label(
            default = "%s//ruby/private/toolset:BUILD.gem.library.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
    implementation = _ruby_install_gems,
)
