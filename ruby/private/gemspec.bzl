load(
    "//ruby/private/tools:deps.bzl",
    _transitive_deps = "transitive_deps",
)
load(
    "//ruby/private:providers.bzl",
    "RubyGem",
    "RubyLibrary",
)

def _get_transitive_srcs(srcs, deps):
    for dep in deps:
        print(dep[RubyLibrary].transitive_ruby_srcs)

    return depset(
        srcs,
        transitive = [dep[RubyLibrary].transitive_ruby_srcs for dep in deps],
    )

def _unique_elems(list):
    _out = []
    _prev = None
    for elem in sorted(list):
        if _prev != elem:
            _out.append(elem)

    return _out

def _rb_gem_impl(ctx):
    gemspec = ctx.actions.declare_file("%s.gemspec" % ctx.attr.gem_name)

    _ruby_files = []
    _require_paths = []
    for file in _get_transitive_srcs([], ctx.attr.deps).to_list():
        _ruby_files.append(file.short_path)
        _require_paths.append(file.dirname)

    _require_paths = _unique_elems(_require_paths)  # Set is not supported in Starlark

    ctx.actions.expand_template(
        template = ctx.file._gemspec_template,
        output = gemspec,
        substitutions = {
            "{name}": "\"%s\"" % ctx.label.name,
            "{srcs}": repr(_ruby_files),
            "{authors}": repr(ctx.attr.authors),
            "{version}": ctx.attr.version,
            "{require_paths}": repr(_require_paths),
        },
    )

    return [
        DefaultInfo(files = _get_transitive_srcs([gemspec], ctx.attr.deps)),
        RubyGem(
            ctx = ctx,
            version = ctx.attr.version,
        ),
    ]

_ATTRS = {
    "version": attr.string(
        default = "0.0.1",
    ),
    "authors": attr.string_list(),
    "deps": attr.label_list(
        allow_files = True,
    ),
    "data": attr.label_list(
        allow_files = True,
    ),
    "_gemspec_template": attr.label(
        allow_single_file = True,
        default = "gemspec_template.tpl",
    ),
    "gem_name": attr.string(),
    "srcs": attr.label_list(
        allow_files = True,
        default = [],
    ),
    "require_paths": attr.string_list(),
}

rb_gemspec = rule(
    implementation = _rb_gem_impl,
    attrs = _ATTRS,
    provides = [DefaultInfo, RubyGem],
)
