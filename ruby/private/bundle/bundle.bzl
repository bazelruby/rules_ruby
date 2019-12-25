load(
    "//ruby/private:constants.bzl",
    "BUNDLER",
    "BUNDLER_BINARY",
    "RULES_RUBY_WORKSPACE_NAME",
)

def install_gem(ctx, gem_name, gem_version, gem_home = gem_name):
    args = [
        ruby_path(ctx),
        "install_gem.rb",
        gem_name,
        gem_version,
        gem_home,
    ]

    result = ctx.execute(args, environment = environment)

    if result.return_code:
        message = "Failed to install gem {} version {} with install_gem.rb, ruby={}: error={}".format(
            gem_name,
            gem_version,
            interpreter,
            result.stderr,
        )
        fail(message)

def install_bundler(ctx, ruby_path):
    install_gem(
        ctx,
        ruby_path(ctx),
        "bundler",
        "bundler",
        ctx.attr.version,
    )

def ruby_path(ctx):
    return ctx.path(ctx.attr.ruby_interpreter)

def ruby_exec(ctx, incpaths = []):
    args = [ruby_path(ctx)]  # ruby
    if ctx.attr.rubygems:
        args.append("--disable=gems")
    else:
        args.append("--enable=gems")

    include_args = [["-I", _relative(incpath)] for incpath in incpaths]
    args.append(include_args)

    print("ruby_exec: ARGS ARE: ", args)

def _bundle_install_impl(ctx):
    # Re-create bundle-friendly environment in the output container
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")

    if ctx.attr.gemspec:
        ctx.symlink(ctx.attr.gemspec, ctx.name + ".gemspec")

    ctx.symlink(ctx.attr._create_bundle_build_file, "create_bundle_build_file.rb")
    ctx.symlink(ctx.attr._install_bundler, "install_bundler.rb")

    bundler = Label(BUNDLER)

    args.append([
        "-I",  # Used to tell Ruby where to load the library scripts
        "bundler/lib",
        BUNDLER_BINARY,  # run
        "install",  #   > bundle install
        "--deployment",  # In the deployment mode, gems are dumped to --path and frozen; also .bundle/config file is created
        "--standalone",  # Makes a bundle that can work without depending on Rubygems or Bundler at runtime.
        "--frozen",  # Do not allow the Gemfile.lock to be updated after this install.
        "--binstubs=bin",  # Creates a directory and place any executables from the gem there.
        "--path=lib",  # The location to install the specified gems to.
    ])

    result = ctx.execute(args, quiet = False)

    if result.return_code:
        fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))

    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        ctx.path(ruby),  # ruby interpreter
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
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

bundle_install = repository_rule(
    implementation = _bundle_install_impl,
    attrs = {
        "ruby_sdk": attr.string(
            default = DEFAULT_RUBY_TOOLCHAIN,
        ),
        "ruby_interpreter": attr.label(
            default = DEFAULT_RUBY_SDK_LABEL,
        ),
        "path": attr.string(
            default = "lib",
        ),
        "rubygems": attr.bool(
            default = True,
        ),
        "deployment": attr.bool(
            default = True,
        ),
        "gemfile": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "standalone": attr.bool(
            default = True,
        ),
        "standalone_groups": attr.string_list(
            default = None,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True,
        ),
        "version": attr.string(
            default = "2.0.2",
        ),
        "gemspec": attr.label(
            allow_single_file = True,
            mandatory = False,
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
        ),
        "_install_bundler": attr.label(
            default = "%s//ruby/private/bundle:install_gem.rb" % (
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
