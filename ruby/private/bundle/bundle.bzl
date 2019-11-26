load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

def _get_interpreter_label(repository_ctx, ruby_sdk):
    # TODO(yugui) Support windows as rules_nodejs does
    return Label("%s//:ruby" % ruby_sdk)

def _get_bundler_label(repository_ctx, ruby_sdk):
    # TODO(yugui) Support windows as rules_nodejs does
    return Label("%s//:bundler/exe/bundler" % ruby_sdk)

def _get_bundler_lib_label(repository_ctx, ruby_sdk):
    # TODO(yugui) Support windows as rules_nodejs does
    return Label("%s//:bundler/lib" % ruby_sdk)

def bundle_install_impl(ctx):
    ctx.symlink(ctx.attr.gemfile, "Gemfile")
    ctx.symlink(ctx.attr.gemfile_lock, "Gemfile.lock")
    ctx.symlink(ctx.attr._create_bundle_build_file, "create_bundle_build_file.rb")

    # TODO(kig) Make Gemspec reference from Gemfile actually work
    if ctx.attr.gemspec:
        ctx.symlink(ctx.attr.gemspec, ctx.path(ctx.attr.gemspec).basename)

    ruby = _get_interpreter_label(ctx, ctx.attr.ruby_sdk)
    bundler = _get_bundler_label(ctx, ctx.attr.ruby_sdk)

    # Install the Gems into the workspace
    args = [
        "env",
        "-i",  # remove all environment variables
        ctx.path(ruby),  # ruby
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # Used to tell Ruby where to load the library scripts
        ctx.path(bundler).dirname.dirname.get_child("lib"),
        ctx.path(bundler),  # run
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

    # exclude any specified files
    exclude = []
    for gem, globs in ctx.attr.excludes.items():
        expanded = ["lib/ruby/*/gems/%s-*/%s" % (gem, glob) for glob in globs]
        exclude.extend(expanded)

    # Create the BUILD file to expose the gems to the WORKSPACE
    args = [
        "env",
        "-i",  # remove all environment variables
        ctx.path(ruby),  # ruby interpreter
        "--disable-gems",  # prevent the addition of gem installation directories to the default load path
        "-I",  # -I lib (adds this folder to $LOAD_PATH where ruby searchesf for things)
        ctx.path(bundler).dirname.dirname.get_child("lib"),
        "create_bundle_build_file.rb",  # The template used to created bundle file
        "BUILD.bazel",  # Bazel build file (can be empty)
        "Gemfile.lock",  # Gemfile.lock where we list all direct and transitive dependencies
        ctx.name,  # Name of the target
        repr(exclude),
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
                "{exclude}": repr(exclude),
                "{workspace_name}": RULES_RUBY_WORKSPACE_NAME,
            },
        )

bundle_install = repository_rule(
    implementation = bundle_install_impl,
    attrs = {
        "ruby_sdk": attr.string(
            default = "@org_ruby_lang_ruby_host",
        ),
        "gemfile": attr.label(
            allow_single_file = True,
        ),
        "gemfile_lock": attr.label(
            allow_single_file = True,
        ),
        "gemspec": attr.label(
            allow_single_file = True,
        ),
        "excludes": attr.string_list_dict(
            doc = "List of glob patterns per gem to be excluded from the library",
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
