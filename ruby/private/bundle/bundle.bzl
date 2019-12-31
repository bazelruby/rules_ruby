load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

BUNDLE_INSTALL_PATH = "lib"
BUNDLE_BINARY = "bundler/exe/bundler"

# TODO: do not hard-code this
GEM_HOME = "lib/ruby/2.5.0/"

def upgrade_bundler(ctx, interpreter, environment):
    # Now we are running bundle install
    args = [
        interpreter,  # ruby
        "--enable=gems",  # bundler must run with rubygems enabled
        "",
        ".",
        "-I",  # Used to tell Ruby where to load the library scripts
        "lib",  # Add vendor/bundle to the list of resolvers
        BUNDLE_BINARY,  # our binary
    ] + extra_args

    # print("running bundler with args\n", args)

    result = ctx.execute(
        args,
        quiet = False,
    )

    return result
def run_bundler(ctx, interpreter, environment, extra_args):
    # Now we are running bundle install
    args = [
        interpreter,  # ruby
        "--enable=gems",  # bundler must run with rubygems enabled
        "-I",
        ".",
        "-I",  # Used to tell Ruby where to load the library scripts
        "lib",  # Add vendor/bundle to the list of resolvers
        BUNDLE_BINARY,  # our binary
    ] + extra_args

    # print("running bundler with args\n", args)

    result = ctx.execute(
        args,
        quiet = False,
    )

    return result

# Sets local bundler config values
def set_bundler_config(ctx, interpreter, environment):
    # Bundler is deprecating various flags in favor of the configuration.
    # HOWEVER — for reasons I can't explain, Bazel runs "bundle install" *prior*
    # to setting these flags. So the flags are then useless until we can force the
    # order and ensure that Bazel first downloads Bundler, then sets config, then
    # runs bundle install. Until then, it's a wild west out here.
    #
    # Set local configuration options for bundler
    bundler_config = {
        "binstubs": "bin",
        "deployment": "'true'",
        "standalone": "'true'",
        "frozen": "'true'",
        "without": "development,test",
        "path": "lib",
        "jobs": "20",
    }

    for option, value in [(option, value) for option, value in bundler_config.items()]:
        args = [
            "config",
            "--local",
            option,
            value,
        ]

        result = run_bundler(ctx, interpreter, environment, args)
        if result.return_code:
            message = "Failed to set bundle config {} to {}: {}".format(
                option,
                value,
                result.stderr,
            )
            fail(message)

def install_bundler(ctx, interpreter, install_bundler, dest, version, environment):
    args = [interpreter, install_bundler, version, dest]

    result = ctx.execute(args, environment = environment)
    if result.return_code:
        message = "Failed to evaluate ruby snippet with {}: {}".format(
            interpreter,
            result.stderr,
        )
        fail(message)

def bundle_install_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._create_bundle_build_file, "create_bundle_build_file.rb")
    ctx.symlink(ctx.attr._install_bundler, "install_bundler.rb")

    environment = {"RUBYOPT": "--enable-gems", "GEM_HOME": GEM_HOME}

    ruby = ctx.attr.ruby_interpreter
    interpreter = ctx.path(ruby)

    install_bundler(
        ctx,
        interpreter,
        "install_bundler.rb",
        "bundler",
        ctx.attr.version,
        environment,
    )
    bundler = Label("//:" + BUNDLE_BINARY)

    # Set Bundler config in the .bundle/config file
    set_bundler_config(
        ctx,
        interpreter,
        environment,
    )

    result = run_bundler(
        ctx,
        interpreter,
        environment,
        [
            "install",  #   > bundle install
            "--standalone",  # Makes a bundle that can work without depending on Rubygems or Bundler at runtime.
            "--binstubs=bin",  # Creates a directory and place any executables from the gem there.
            "--path={}".format(BUNDLE_INSTALL_PATH),  # The location to install the specified gems to.
        ],
    )

    if result.return_code:
        fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))

    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        ctx.path(ruby),  # ruby interpreter
        "--enable=gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # -I lib (adds this folder to $LOAD_PATH where ruby searchesf for things)
        "bundler/lib",
        "create_bundle_build_file.rb",  # The template used to created bundle file
        "BUILD.bazel",  # Bazel build file (can be empty)
        "Gemfile.lock",  # Gemfile.lock where we list all direct and transitive dependencies
        ctx.name,  # Name of the target
        repr(ctx.attr.excludes),
        RULES_RUBY_WORKSPACE_NAME,
    ]
    result = ctx.execute(args, quiet = False)

    if result.return_code:
        fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))

        ctx.template(
            "BUILD.bazel",
            ctx.attr._buildfile_template,
            substitutions = {
                "{repo_name}": ctx.name,
                "{workspace_name}": RULES_RUBY_WORKSPACE_NAME,
            },
        )

ruby_bundle = repository_rule(
    implementation = bundle_install_impl,
    attrs = {
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
            default = "2.1.2",
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
    },
)
