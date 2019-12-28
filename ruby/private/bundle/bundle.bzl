load(
    "//ruby/private:constants.bzl",
    "BUNDLE_DEFAULT_DESTINATION",
    "RULES_RUBY_WORKSPACE_NAME",
)

# Installs arbitrary gem/version combo to any location specified by gem_home
# The tool used here is ruby_install_gem.rb
def download_gem(
        ctx,
        interpreter,
        gem_name,
        gem_version,
        gem_home = BUNDLE_DEFAULT_DESTINATION):
    print(">>> install_bundled_gems() <<<")

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

def download_bundler_gem(ctx, interpreter, bundler_version, gem_home):
    print(">>> download_bundler_gem() <<<")
    return download_gem(ctx, interpreter, "bundler", bundler_version, gem_home)

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
def _ruby_bundle_install_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._ruby_bundle_install, "ruby_bundle_install.rb")
    ctx.symlink(ctx.attr._ruby_install_gem, "ruby_install_gem.rb")
    ctx.symlink(ctx.attr._ruby_helpers, "ruby_helpers.rb")
    ctx.symlink(ctx.attr._build_header_template, "BUILD.header.tpl")
    ctx.symlink(ctx.attr._build_bundle_template, "BUILD.bundler.tpl")
    ctx.symlink(ctx.attr._build_gem_library_template, "BUILD.gem.library.tpl")
    ctx.symlink(ctx.attr._build_gem_binary_template, "BUILD.gem.binary.tpl")

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
        "ruby_bundle_install.rb",  # An actual script we'll be running.
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

ruby_bundle_install = repository_rule(
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_toolchain",
        ),
        "ruby_interpreter": attr.label(
            default = "@org_ruby_lang_ruby_toolchain//:ruby",
        ),
        "rubygems_sources": attr.string_list(
            default = ["https://rubygems.org"],
            mandatory = True,
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
            default = BUNDLE_DEFAULT_DESTINATION,
        ),
        "bundler_version": attr.string(
            default = "2.1.2",
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
        "_ruby_bundle_install": attr.label(
            default = "%s//ruby/private/toolset:ruby_bundle_install.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "Generates the BUILD file for the entire bundle",
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
        "_build_bundle_template": attr.label(
            default = "%s//ruby/private/toolset:BUILD.bundler.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_build_header_template": attr.label(
            default = "%s//ruby/private/toolset:BUILD.header.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
    implementation = _ruby_bundle_install_impl,
)
