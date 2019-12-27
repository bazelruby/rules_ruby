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

def run_bundler(ctx, interpreter, environment, gem_home, extra_args, quiet = True):
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
        fail("BUNDLE {} FAILED: %s%s".format(extra_args[0]) % (result.stdout, result.stderr))

def _ruby_bundle_install_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._ruby_bundle_install, "ruby_bundle_install.rb")
    ctx.symlink(ctx.attr._ruby_install_gem, "ruby_install_gem.rb")
    ctx.symlink(ctx.attr._ruby_helpers, "ruby_helpers.rb")
    ctx.symlink(ctx.attr._build_bundle_template, "BUILD.bundler.tpl")
    ctx.symlink(ctx.attr._build_gem_library_template, "BUILD.gem.library.tpl")
    ctx.symlink(ctx.attr._build_gem_binary_template, "BUILD.gem.binary.tpl")

    gem_home = ctx.attr.gem_home
    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": gem_home, "GEM_PATH": gem_home}

    # Install Bundler Gem itself
    install_bundler(
        ctx,
        interpreter_path,
        ctx.attr.bundler_version,
        gem_home,
    )

    bundler = Label("//vendor/bundle/exe/bundler")

    # Bundler is deprecating ¬ ¬
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

    # This runs bundle install
    run_bundler(
        ctx,
        interpreter_path,
        environment,
        gem_home,
        ["install", "--binstubs=bin"],
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
        "-w",
        RULES_RUBY_WORKSPACE_NAME,
    ]

    result = ctx.execute(args, environment = environment, quiet = False)
    if result.return_code:
        fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))

def _ruby_install_gem(ctx):
    ctx.symlink(ctx.attr._ruby_install_gem, "ruby_install_gem.rb")
    ctx.symlink(ctx.attr._ruby_bundle_install, "ruby_bundle_install.rb")
    ctx.symlink(ctx.attr._ruby_helpers, "ruby_helpers.rb")

    ruby = ctx.attr.ruby_interpreter

    interpreter_path = ctx.path(ruby)

    gem_home = ctx.attr.gem_home
    gem_name = ctx.attr.gem_name
    gem_version = ctx.attr.gem_version

    # Install the Gems into the workspace
    args = [
        ctx.path(ruby),  # ruby
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
        "ruby_install_gem.rb",  # gem installer
        gem_name,
        gem_version,
        ".",
    ]

    print("installing GEM", gem_name, ", v(", gem_version, ") to [", gem_home, "]s")
    result = ctx.execute(args, quiet = False)

    if result.return_code:
        fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))
    else:
        return 0

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
    },
    implementation = _ruby_bundle_install_impl,
)

ruby_gem_install = repository_rule(
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_toolchain",
        ),
        "ruby_interpreter": attr.label(
            default = "@org_ruby_lang_ruby_toolchain//:ruby",
        ),
        "gem_name": attr.string(
            mandatory = True,
        ),
        "gem_version": attr.string(
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
            default = "%s//ruby/private/bundle:ruby_install_gem.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_ruby_helpers": attr.label(
            default = "%s//ruby/private/bundle:ruby_helpers.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            doc = "Generates the BUILD file for the entire bundle",
            allow_single_file = True,
        ),
    },
    implementation = _ruby_install_gem,
)
