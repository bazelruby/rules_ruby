load(
    "//ruby/private:constants.bzl",
    "BUNDLE_ATTRS",
    "BUNDLE_BINARY",
    "BUNDLE_BIN_PATH",
    "BUNDLE_PATH",
    "RULES_RUBY_WORKSPACE_NAME",
    "SCRIPT_BUILD_FILE_GENERATOR",
    "SCRIPT_INSTALL_GEM",
)
load("//ruby/private:providers.bzl", "RubyRuntimeInfo")

# Runs bundler with arbitrary arguments
# eg: run_bundler(runtime_ctx, [ "lock", " --gemfile", "Gemfile.rails5" ])
def run_bundler(runtime_ctx, bundler_arguments, previous_result):
    # Now we are running bundle install
    bundler_command = bundler_arguments[0]
    bundler_args = []

    # add --verbose to all commands except install
    if bundler_command != "install":
        bundler_args.append("--verbose")

    bundler_args += bundler_arguments[1:]

    args = [
        runtime_ctx.interpreter,  # ruby
        "-I",  # Used to tell Ruby where to load the library scripts
        BUNDLE_PATH,  # Add vendor/bundle to the list of resolvers
        BUNDLE_BINARY,  # our binary
    ] + [bundler_command] + bundler_args

    # print("Bundler Command:\n\n", args)

    return runtime_ctx.ctx.execute(
        args,
        quiet = False,
        environment = runtime_ctx.environment,
    )

#
# Sets local bundler config values by calling
#
# $ bundle config --local | --global config-option config-value
#
# @config_category can be either 'local' or 'global'
def set_bundler_config(runtime_ctx, previous_result, config_category = "local"):
    # Bundler is deprecating various flags in favor of the configuration.
    # HOWEVER — for reasons I can't explain, Bazel runs "bundle install" *prior*
    # to setting these flags. So the flags are then useless until we can force the
    # order and ensure that Bazel first downloads Bundler, then sets config, then
    # runs bundle install. Until then, it's a wild west out here.
    #
    # Set local configuration options for bundler
    bundler_config = {
        "deployment": "true",
        "standalone": "true",
        "force": "false",
        "redownload": "false",
        "frozen": "true",
        "path": BUNDLE_PATH,
        "jobs": "20",
        "shebang": runtime_ctx.interpreter,
    }

    last_result = previous_result

    for option, value in bundler_config.items():
        args = ["config", "set", "--%s" % (config_category), option, value]
        result = run_bundler(runtime_ctx, args, last_result)
        last_result = result
        if result.return_code:
            message = "Failed to set bundle config {} to {}: {}".format(
                option,
                value,
                result.stderr,
            )
            fail(message)

    return last_result

# This function is called "pure_ruby" because it downloads and unpacks the gem
# file into a given folder, which for gems without C-extensions is the same
# as install. To support gems that have C-extensions, the Ruby file install_gem.rb
# will need to be modified to use Gem::Installer.at(path).install(gem) API.
def install_pure_ruby_gem(runtime_ctx, gem_name, gem_version, folder):
    # USAGE: ./install_bundler.rb gem-name gem-version destination-folder
    args = [
        runtime_ctx.interpreter,
        SCRIPT_INSTALL_GEM,
        gem_name,
        gem_version,
        folder,
    ]
    result = runtime_ctx.ctx.execute(args, environment = runtime_ctx.environment)
    if result.return_code:
        message = "Failed to install gem {}-{} to {} with {}: {}".format(
            gem_name,
            gem_version,
            folder,
            runtime_ctx.interpreter,
            result.stderr,
        )
        fail(message)
    else:
        return result

def install_bundler(runtime_ctx, bundler_version):
    return install_pure_ruby_gem(
        runtime_ctx,
        "bundler",
        bundler_version,
        "bundler",
    )

def bundle_install(runtime_ctx, previous_result):
    result = run_bundler(
        runtime_ctx,
        [
            "install",
            "--binstubs={}".format(BUNDLE_BIN_PATH),
            "--path={}".format(BUNDLE_PATH),
            "--deployment",
            "--standalone",
            "--frozen",
        ],
        previous_result,
    )

    if result.return_code:
        fail("bundle install failed: %s%s" % (result.stdout, result.stderr))
    else:
        return result

def generate_bundle_build_file(runtime_ctx, previous_result):
    # Create the BUILD file to expose the gems to the WORKSPACE
    # USAGE: ./create_bundle_build_file.rb BUILD.bazel Gemfile.lock repo-name [excludes-json] workspace-name
    args = [
        runtime_ctx.interpreter,  # ruby interpreter
        "--enable=gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # -I lib (adds this folder to $LOAD_PATH where ruby searches for things)
        "bundler/lib",
        SCRIPT_BUILD_FILE_GENERATOR,  # The template used to created bundle file
        "BUILD.bazel",  # Bazel build file (can be empty)
        "Gemfile.lock",  # Gemfile.lock where we list all direct and transitive dependencies
        runtime_ctx.ctx.name,  # Name of the target
        repr(runtime_ctx.ctx.attr.excludes),
        RULES_RUBY_WORKSPACE_NAME,
    ]

    result = runtime_ctx.ctx.execute(args, quiet = False)
    if result.return_code:
        fail("build file generation failed: %s%s" % (result.stdout, result.stderr))

def _ruby_bundle_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._create_bundle_build_file, SCRIPT_BUILD_FILE_GENERATOR)
    ctx.symlink(ctx.attr._install_bundler, SCRIPT_INSTALL_GEM)

    bundler_version = ctx.attr.bundler_version

    # Setup this provider that we pass around between functions for convenience
    runtime_ctx = RubyRuntimeInfo(
        ctx = ctx,
        interpreter = ctx.path(ctx.attr.ruby_interpreter),
        environment = {"RUBYOPT": "--enable-gems"},
    )

    # 1. Install the right version of the Bundler Gem
    result = install_bundler(runtime_ctx, bundler_version)

    # 2. Set Bundler config in the .bundle/config file
    result = set_bundler_config(runtime_ctx, result)

    # 3. Run bundle install
    result = bundle_install(runtime_ctx, result)

    # 4. Generate the BUILD file for the bundle
    generate_bundle_build_file(runtime_ctx, result)

ruby_bundle_install = repository_rule(
    implementation = _ruby_bundle_impl,
    attrs = BUNDLE_ATTRS,
)
