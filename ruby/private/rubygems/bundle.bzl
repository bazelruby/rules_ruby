load(
    "//ruby/private/rubygems:shared.bzl",
    "GEM_ATTRS",
    "TOOLS_RUBY_BUNDLE",
    "ruby_runtime_environment",
    "run_bundler",
    "symlink_context",
)
load(
    "//ruby/private/rubygems:gemset.bzl",
    "generate_gemfile",
    "install_bundler",
)
load(
    "//ruby/private:constants.bzl",
    "RULES_RUBY_WORKSPACE_NAME",
)

# Rule implementation
def _ruby_bundle_impl(ctx, gemfile = None):
    symlink_context(ctx)

    gem_home = ctx.attr.gem_home
    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)
    environment = ruby_runtime_environment(gem_home)
    rubygems_sources = ctx.attr.rubygems_sources

    install_bundler(
        ctx,
        interpreter_path,
        gem_home,
        rubygems_sources,
        environment,
    )

    bundler = Label("//vendor/bundle/exe/bundler")

    # if we are passed gemfile from the arguments,
    # generate the lock file first.
    if gemfile != None:
        bundler_args = [
            "install",
            "--path",
            gem_home,
            "--gemfile",
            gemfile,
        ]
        run_bundler(
            ctx,
            interpreter_path,
            environment,
            gem_home,
            bundler_args,
        )
    else:
        gemfile = ctx.attr.gemfile.name

    # Run on a lock file
    bundler_args = [
        "install",
        "--gemfile",
        gemfile,
        "--path",
        gem_home,
        "--binstubs=bin",
        "--deployment",
        "--frozen",
        "--standalone",
    ]

    run_bundler(
        ctx,
        interpreter_path,
        environment,
        gem_home,
        bundler_args,
    )

    gemfile_lock = gemfile + ".lock"

    #
    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        ctx.path(ruby),  # ruby interpreter
        "--disable=gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # -I lib (adds this folder to $LOAD_PATH where ruby
        gem_home + "/bundler/lib",  # loading file
        "-I",  # Used to tell Ruby where to load the library scripts
        gem_home,  # Add vendor/bundle to the list of resolvers
        TOOLS_RUBY_BUNDLE,  # An actual script we'll be running.
        "-o",
        "BUILD.bazel",  # Bazel build file (can be empty)
        "-l",
        gemfile_lock,  # Gemfile.lock where we list all direct and transitive dependencies
        "-p",
        gem_home,
        "-r",
        ctx.name,  # Name of the target
        "-e",
        repr(ctx.attr.excludes),  # Excludes are in JSON format
        "-w",
        RULES_RUBY_WORKSPACE_NAME,
    ]

    # print("generating build file with command\n", args)

    result = ctx.execute(args, environment = environment, quiet = False)
    if result.return_code:
        fail("Failed to create build file: %s%s" % (result.stdout, result.stderr))

ruby_bundle = repository_rule(
    implementation = _ruby_bundle_impl,
    attrs = GEM_ATTRS,
)

def _ruby_gemset(ctx):
    repo = ctx.attr.name
    gems = ctx.attr.gems
    gem_home = repo + "/" + ctx.attr.gem_home

    rubygems_sources = ctx.attr.rubygems_sources

    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    gemfile = "Gemfile"

    generate_gemfile(
        ctx,
        gems,
        rubygems_sources,
        gemfile,
    )

    _ruby_bundle_impl(ctx, gemfile)

ruby_gemset = repository_rule(
    attrs = GEM_ATTRS,
    implementation = _ruby_gemset,
)
