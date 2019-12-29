load(
    "//ruby/private:constants.bzl",
    "DEFAULT_GEM_PATH",
    "RUBYGEMS_SOURCES",
    "RULES_RUBY_WORKSPACE_NAME",
    "TEMPLATE_BUILD_FILE_HEADER",
    "TEMPLATE_BUNDLER",
    "TEMPLATE_GEM_AS_BINARY",
    "TEMPLATE_GEM_AS_LIBRARY",
    "TOOLCHAIN_TYPE_NAME",
    "TOOLS_RUBY_BUNDLE",
    "TOOLS_RUBY_GEMSET",
    "TOOLS_RUBY_SHARED",
)
load(
    "//ruby/private/rubygems:gemset.bzl",
    "install_gem",
)

def download_bundler_gem(ctx, interpreter, bundler_version, gem_home):
    print(">>> download_bundler_gem() <<<")
    return install_gem(ctx, interpreter, "bundler", bundler_version, gem_home)

def run_bundler(ctx, interpreter, environment, gem_home, extra_args, quiet = True):
    print(">>> run_bundler({}) <<<".format(extra_args[0]))

    # Now we are running bundle install
    args = [
        interpreter,  # ruby
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # Used to tell Ruby where to load the library scripts
        gem_home,  # Add vendor/bundle to the list of resolvers
        gem_home + "/exe/bundler",  # our binary
    ] + extra_args

    result = ctx.execute(args, environment = environment, quiet = quiet)

    if result.return_code:
        fail(">>> run_bundler({}) FAILED: %s%s".format(extra_args[0]) % (result.stdout, result.stderr))

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

# Rule implementation
def _ruby_bundle_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._tools_bundle, TOOLS_RUBY_BUNDLE)
    ctx.symlink(ctx.attr._tools_gemset, TOOLS_RUBY_GEMSET)
    ctx.symlink(ctx.attr._tools_shared, TOOLS_RUBY_SHARED)
    ctx.symlink(ctx.attr._build_header_template, TEMPLATE_BUILD_FILE_HEADER)
    ctx.symlink(ctx.attr._build_bundle_template, TEMPLATE_BUNDLER)
    ctx.symlink(ctx.attr._template_gem_as_library, TEMPLATE_GEM_AS_LIBRARY)
    ctx.symlink(ctx.attr._template_gem_as_binary, TEMPLATE_GEM_AS_BINARY)

    gem_home = ctx.attr.gem_home
    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

    print("Installing BUNDLER")

    # Install Bundler Gem itself
    download_bundler_gem(
        ctx,
        interpreter_path,
        ctx.attr.bundler_version,
        gem_home,
    )

    bundler = Label("//vendor/bundle/exe/bundler")

    # This runs bundle install
    run_bundler(
        ctx,
        interpreter_path,
        environment,
        gem_home,
        [
            "install",
            "--binstubs=bin",
            "--deployment",
            "--frozen",
            "--standalone",
            "--path={}".format(gem_home),
        ],
    )

    #
    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        ctx.path(ruby),  # ruby interpreter
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # -I lib (adds this folder to $LOAD_PATH where ruby
        gem_home + "/bundler/lib",  # loading file
        "-I",  # Used to tell Ruby where to load the library scripts
        gem_home,  # Add vendor/bundle to the list of resolvers
        "ruby_bundle.rb",  # An actual script we'll be running.
        "-o",
        "BUILD.bazel",  # Bazel build file (can be empty)
        "-l",
        "Gemfile.lock",  # Gemfile.lock where we list all direct and transitive dependencies
        "-p",
        gem_home,
        "-r",
        ctx.name,  # Name of the target
        "-e",
        repr(ctx.attr.excludes),  # Excludes are in JSON format
        "-v",
        "-w",
        RULES_RUBY_WORKSPACE_NAME,
    ]

    print("GENERATING BUILD FILE")

    result = ctx.execute(args, environment = environment, quiet = False)
    if result.return_code:
        fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))

ruby_bundle = repository_rule(
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_toolchain",
        ),
        "ruby_interpreter": attr.label(
            default = "@org_ruby_lang_ruby_toolchain//:ruby",
        ),
        "rubygems_sources": attr.string_list(
            default = RUBYGEMS_SOURCES,
        ),
        "gemfile": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "gem_home": attr.string(
            default = DEFAULT_GEM_PATH,
        ),
        "bundler_version": attr.string(
            default = "2.1.2",
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),
        "_lib/rules_ruby/gemset": attr.label(
            default = "%s//ruby/private/rubygems:lib/rules_ruby/gemset.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_ruby_bundle": attr.label(
            default = "%s//ruby/private/rubygems:ruby_bundle.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "Generates the BUILD file for the entire bundle",
            allow_single_file = True,
        ),
        "_tools_shared": attr.label(
            default = "%s//ruby/private/rubygems:ruby_helpers.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "Generates the BUILD file for the entire bundle",
            allow_single_file = True,
        ),
        "_template_gem_as_binary": attr.label(
            default = "%s//ruby/private/rubygems:BUILD.gem.binary.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_template_gem_as_library": attr.label(
            default = "%s//ruby/private/rubygems:BUILD.gem.library.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_build_bundle_template": attr.label(
            default = "%s//ruby/private/rubygems:BUILD.bundler.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_build_header_template": attr.label(
            default = "%s//ruby/private/rubygems:BUILD.header.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
    implementation = _ruby_bundle_impl,
)
