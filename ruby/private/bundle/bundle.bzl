load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

def install_bundler(ctx, interpreter, install_bundler, dest, version):
    args = [interpreter, install_bundler, version, dest]
    environment = {"RUBYOPT": "--enable-gems"}

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

    # TODO(kig) Make Gemspec reference from Gemfile actually work
    if ctx.attr.gemspec:
        ctx.symlink(ctx.attr.gemspec, ctx.path(ctx.attr.gemspec).basename)

    ruby = ctx.attr.ruby_interpreter
    interpreter_path = ctx.path(ruby)

    install_bundler(
        ctx,
        interpreter_path,
        "install_bundler.rb",
        "bundler",
        ctx.attr.version,
    )

    bundler = Label("//:bundler/exe/bundler")

    # Install the Gems into the workspace
    args = [
        ctx.path(ruby),  # ruby
        "--enable-gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # Used to tell Ruby where to load the library scripts
        "bundler/lib",
        "bundler/exe/bundler",  # run
        "install",  #   > bundle install
        "--deployment",  # In the deployment mode, gems are dumped to --path and frozen; also .bundle/config file is created
        "--standalone",  # Makes a bundle that can work without depending on Rubygems or Bundler at runtime.
        "--frozen",  # Do not allow the Gemfile.lock to be updated after this install.
        "--binstubs=bin",  # Creates a directory and place any executables from the gem there.
        "--path=lib",  # The location to install the specified gems to.
    ]
    result = ctx.execute(args, quiet = False)

    if result.return_code:
        fail("Failed to install gems: %s%s" % (result.stdout, result.stderr))

    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        ctx.path(ruby),  # ruby interpreter
        "--enable-gems",  # prevent the addition of gem installation directories to the default load path
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
            default = "2.0.2",
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
