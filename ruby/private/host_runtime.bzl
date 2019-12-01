load(":bundler.bzl", "install_bundler")
load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")
load("//ruby/private/tools:repository_context.bzl", "ruby_repository_context")

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
    else:
        return path

def _list_libdirs(ruby):
    """List the LOAD_PATH of the ruby"""
    paths = ruby.eval(ruby, 'print $:.join("\\n")')
    paths = sorted(paths.split("\n"))
    rel_paths = [_relativate(path) for path in paths]
    return (paths, rel_paths)

def _install_dirs(ctx, ruby, *names):
    paths = sorted([ruby.rbconfig(ruby, name) for name in names])
    rel_paths = [_relativate(path) for path in paths]
    for i, (path, rel_path) in enumerate(zip(paths, rel_paths)):
        if not _is_subpath(path, paths[:i]):
            ctx.symlink(path, rel_path)
    return rel_paths

def _install_host_ruby(ctx, ruby):
    # Places SDK
    ctx.symlink(ruby.interpreter_realpath, ruby.rel_interpreter_path)

    # Places the interpreter at a predictable place regardless of the actual binary name
    # so that bundle_install can depend on it.
    ctx.template(
        "ruby",
        ctx.attr._interpreter_wrapper_template,
        substitutions = {
            "{workspace_name}": ctx.name,
            "{rel_interpreter_path}": ruby.rel_interpreter_path,
        },
    )

    # Install lib
    paths, rel_paths = _list_libdirs(ruby)
    for i, (path, rel_path) in enumerate(zip(paths, rel_paths)):
        if not _is_subpath(rel_path, rel_paths[:i]):
            ctx.symlink(path, rel_path)

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
        libdirs = rel_paths,
        static_library = _relativate(static_library),
        shared_library = _relativate(shared_library),
    )

def _ruby_host_runtime_impl(ctx):
    # Locates path to the interpreter
    if ctx.attr.interpreter_path:
        interpreter_path = ctx.path(ctx.attr.interpreter_path)
    else:
        interpreter_path = ctx.which("ruby")
    if not interpreter_path:
        fail(
            "Command 'ruby' not found. Set $PATH or specify interpreter_path",
            "interpreter_path",
        )

    ruby = ruby_repository_context(ctx, interpreter_path)

    installed = _install_host_ruby(ctx, ruby)
    install_bundler(
        ctx,
        interpreter_path,
        ctx.path(ctx.attr._install_bundler).realpath,
        "bundler",
    )

    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{ruby_path}": repr(ruby.rel_interpreter_path),
            "{ruby_basename}": repr(ruby.interpreter_name),
            "{includes}": repr(installed.includedirs),
            "{hdrs}": repr(["%s/**/*.h" % path for path in installed.includedirs]),
            "{static_library}": repr(installed.static_library),
            "{shared_library}": repr(installed.shared_library),
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
        },
        executable = False,
    )

ruby_host_runtime = repository_rule(
    implementation = _ruby_host_runtime_impl,
    attrs = {
        "interpreter_path": attr.string(),
        "_install_bundler": attr.label(
            default = "%s//ruby/private:install_bundler.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_buildfile_template": attr.label(
            default = "%s//ruby/private:BUILD.host_runtime.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
