load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")
load("//ruby/private/toolchains:repository_context.bzl", "ruby_repository_context")

def _install_ruby_version(ctx, version):
    ctx.download_and_extract(
        url = "https://github.com/rbenv/ruby-build/archive/refs/tags/v20220825.tar.gz",
        sha256 = "55d9363a27486e4ec9623985d7764c5cf8e59cafe58afcf666e81fa148dea2f0",
        stripPrefix = "ruby-build-20220825",
    )

    install_path = "./build"
    result = ctx.execute(
        ["./bin/ruby-build", "--verbose", version, install_path],
        quiet = False,
        timeout = 1600,  # massive timeout because this does a lot and is a beast
    )
    if result.return_code:
        fail("Ruby build failed: %s %s" % (result.stdout, result.stderr))

def _is_subpath(path, ancestors):
    """Determines if path is a subdirectory of one of the ancestors"""
    for ancestor in ancestors:
        if not ancestor.endswith("/"):
            ancestor += "/"
        if path.startswith(ancestor):
            return True
    return False

def _relativate(path):
    if not path:
        return path

    # Assuming that absolute paths start with "/".
    # TODO(yugui) support windows
    if path.startswith("/"):
        return path[1:]
    elif path.startswith("C:/"):
        return path[3:]
    else:
        return path

def _list_libdirs(ruby):
    """List the LOAD_PATH of the ruby"""
    paths = ruby.eval(ruby, "print $:.join(\"\\n\")")
    paths = sorted(paths.split("\n"))
    rel_paths = [_relativate(path) for path in paths]
    return (paths, rel_paths)

def _install_dirs(ctx, ruby, *names):
    paths = sorted([ruby.rbconfig(ruby, name) for name in names])

    # JRuby reports some of the directories as nulls.
    paths = [path for path in paths if path]

    # Sometimes we end up with the same directory multiple times
    # so make sure paths are unique by converting it to set.
    # For example, this is what we have on Fedora 34:
    # $ ruby -rrbconfig -e "p RbConfig::CONFIG['rubyhdrdir']"
    # "/usr/include"
    # $ ruby -rrbconfig -e "p RbConfig::CONFIG['rubyarchhdrdir']"
    # "/usr/include"
    paths = depset(paths).to_list()

    rel_paths = [_relativate(path) for path in paths]
    for i, (path, rel_path) in enumerate(zip(paths, rel_paths)):
        if not _is_subpath(path, paths[:i]):
            ctx.symlink(path, rel_path)
    return rel_paths

def _install_ruby(ctx, ruby):
    # Places SDK
    ctx.symlink(ruby.interpreter_realpath, ruby.rel_interpreter_path)

    # Places the interpreter at a predictable place regardless of the actual binary name
    # so that ruby_bundle can depend on it.
    ctx.template(
        "ruby",
        ctx.attr._interpreter_wrapper_template,
        substitutions = {
            "{workspace_name}": ctx.name,
            "{rel_interpreter_path}": ruby.rel_interpreter_path,
        },
    )

    # Install libruby
    static_library = ruby.expand_rbconfig(ruby, "${libdir}/${LIBRUBY_A}")
    if ctx.path(static_library).exists:
        ctx.symlink(static_library, _relativate(static_library))
    else:
        static_library = None

    shared_library = ruby.expand_rbconfig(ruby, "${libdir}/${LIBRUBY_SO}")
    if ctx.path(shared_library).exists:
        ctx.symlink(shared_library, _relativate(shared_library))
    else:
        shared_library = None

    return struct(
        includedirs = _install_dirs(ctx, ruby, "rubyarchhdrdir", "rubyhdrdir"),
        static_library = _relativate(static_library),
        shared_library = _relativate(shared_library),
    )

def system_ruby_is_correct_version(ctx, version):
    interpreter_path = ctx.which("ruby")

    if not interpreter_path:
        print("Can't find ruby interpreter in the PATH")
        return False

    ruby_version = ctx.execute(["ruby", "-e", "print RUBY_VERSION"]).stdout
    ruby_platform = ctx.execute(["ruby", "-e", "print RUBY_PLATFORM"]).stdout
    if ruby_platform == "java":
        ruby_version = "jruby-" + ruby_version

    have_ruby_version = (version == ruby_version)

    if have_ruby_version:
        print("Found local Ruby SDK version '%s' which matches requested version '%s'" % (ruby_version, version))

    return have_ruby_version

def _ruby_runtime_impl(ctx):
    # If the current version of ruby is correct use that
    version = ctx.attr.version
    if version == "system" or system_ruby_is_correct_version(ctx, version):
        interpreter_path = ctx.which("ruby")
    else:
        _install_ruby_version(ctx, version)
        interpreter_path = ctx.path("./build/bin/ruby")

    if not interpreter_path or not interpreter_path.exists:
        fail(
            "Command 'ruby' not found. Set $PATH or specify interpreter_path",
            "interpreter_path",
        )

    ruby = ruby_repository_context(ctx, interpreter_path)

    installed = _install_ruby(ctx, ruby)

    ruby_platform = ctx.execute(["ruby", "-e", "print RUBY_PLATFORM"]).stdout
    if ruby_platform == "java":
        ruby_platform = "jruby"
    else:
        ruby_platform = "ruby"

    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{includes}": repr(installed.includedirs),
            "{hdrs}": repr(["%s/**/*.h" % path for path in installed.includedirs]),
            "{static_library}": repr(installed.static_library),
            "{shared_library}": repr(installed.shared_library),
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
            "{platform}": ruby_platform,
        },
        executable = False,
    )

ruby_runtime = repository_rule(
    implementation = _ruby_runtime_impl,
    attrs = {
        "version": attr.string(default = "system"),
        "_buildfile_template": attr.label(
            default = "%s//ruby/private/toolchains:BUILD.runtime.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private/toolchains:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
