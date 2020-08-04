load(
    "//ruby/private:providers.bzl",
    "RubyGemInfo",
    "RubyLibraryInfo",
)
load(
    "//ruby/private:constants.bzl",
    "GEMSPEC_ATTRS",
)
load(
    "@rules_pkg//:pkg.bzl",
    "pkg_zip",
)

def _get_transitive_srcs(srcs, deps):
    for dep in deps:
        print(dep[RubyLibraryInfo].transitive_ruby_srcs)

    return depset(
        srcs,
        transitive = [dep[RubyLibraryInfo].transitive_ruby_srcs for dep in deps],
    )

def _unique_elems(list):
    _out = []
    _prev = None
    for elem in sorted(list):
        if _prev != elem:
            _out.append(elem)

    return _out

# Converts gem name and optionally a version into a
# gemspec line "spec.add_[development_]dependency 'gem-name', [ 'gem-version' ]"
def _gem_dependency(name, version = "", development = False):
    dependency_type = "spec.add_development_dependency" if development else "spec.add_runtime_dependency"

    output = "%s '%s'" % (dependency_type, name)
    if version != "":
        output += ", '%s'" % version

    return output

# Converts gem name and optionally to a bullet list
def _markdown_gem_dependency(name, version = ""):
    output = " * %s " % name
    if version != "":
        output += " (version %s) " % (version)

    return output

def _markdown_ul(list = []):
    return ("\n * " + "\n * ".join(list) + "\n")

# Converts a dictionary (key = gem name, value = gem version or None)
# to a string to be inserted into the gemspec.
def _gem_runtime_dependencies(gem_dict = {}):
    dependencies = [_gem_dependency(k, v) for k, v in gem_dict.items()]
    return ("\n  " + "\n  ".join(dependencies))

# Converts a dictionary (key = gem name, value = gem version or None)
# to a string to be inserted into the gemspec.
def _markdown_gem_runtime_dependencies(gem_dict = {}, type = "Runtime"):
    dependencies = [_markdown_gem_dependency(k, v) for k, v in gem_dict.items()]
    output = "\n### %s Dependencies\n\n" % type
    output += "\n  " + "\n  ".join(dependencies) + "\n\n"
    return (output)

def _gem_impl(ctx):
    gemspec = ctx.actions.declare_file("%s.gemspec" % ctx.attr.gem_name)
    gem_readme = ctx.actions.declare_file("README.md")

    _ruby_files = []
    _require_paths = []

    for file in _get_transitive_srcs([], ctx.attr.deps).to_list():
        _ruby_files.append(file.short_path)
        _require_paths.append(file.dirname)

    if len(_ruby_files) == 0:
        _gem_sources = "`git ls-files -z`.split(\"\\x0\").reject { |f| f.match(/^(test|spec|features)\\//) }"
    else:
        _gem_sources = repr(_ruby_files)

    if ctx.attr.gem_homepage != "":
        _gem_title = "[%s](%s)" % (ctx.attr.gem_name, ctx.attr.gem_homepage)
    else:
        _gem_title = "%s" % (ctx.attr.gem_name)

    ctx.actions.expand_template(
        template = ctx.file._gemspec_template,
        output = gemspec,
        substitutions = {
            "{gem_author_emails}": repr(ctx.attr.gem_author_emails),
            "{gem_authors}": repr(ctx.attr.gem_authors),
            "{gem_runtime_dependencies}": _gem_runtime_dependencies(ctx.attr.gem_runtime_dependencies),
            "{gem_description}": ctx.attr.gem_description if ctx.attr.gem_description else ctx.attr.gem_summary,
            "{gem_development_dependencies}": _gem_runtime_dependencies(ctx.attr.gem_development_dependencies),
            "{gem_homepage}": ctx.attr.gem_homepage,
            "{gem_name}": ctx.attr.gem_name,
            "{gem_require_paths}": repr(["lib"]),
            "{gem_sources}": _gem_sources,
            "{gem_summary}": ctx.attr.gem_summary,
            "{gem_version}": ctx.attr.gem_version,
        },
    )

    _dependencies = _markdown_gem_runtime_dependencies(ctx.attr.gem_runtime_dependencies, "Runtime")
    _dependencies += _markdown_gem_runtime_dependencies(ctx.attr.gem_development_dependencies, "Development")

    ctx.actions.expand_template(
        template = ctx.file._readme_template,
        output = gem_readme,
        substitutions = {
            "{gem_authorship}": _markdown_ul(ctx.attr.gem_authors),
            "{gem_runtime_dependencies}": _dependencies,
            "{gem_description}": ctx.attr.gem_description if ctx.attr.gem_description else ctx.attr.gem_summary,
            "{gem_name}": ctx.attr.gem_name,
            "{gem_summary}": ctx.attr.gem_summary,
            "{gem_title}": _gem_title,
            "{gem_version}": ctx.attr.gem_version,
        },
    )

    return [
        DefaultInfo(
            files = _get_transitive_srcs([gemspec, gem_readme], ctx.attr.deps),
        ),
        RubyGemInfo(
            ctx = ctx,
            gem_author_emails = ctx.attr.gem_author_emails,
            gem_authors = ctx.attr.gem_authors,
            gem_runtime_dependencies = ctx.attr.gem_runtime_dependencies,
            gem_description = ctx.attr.gem_description,
            gem_development_dependencies = ctx.attr.gem_development_dependencies,
            gem_homepage = ctx.attr.gem_homepage,
            gem_name = ctx.attr.gem_name,
            gem_summary = ctx.attr.gem_summary,
            gem_version = ctx.attr.gem_version,
        ),
    ]

gemspec = rule(
    implementation = _gem_impl,
    attrs = GEMSPEC_ATTRS,
    provides = [DefaultInfo, RubyGemInfo],
)

def gem(
        name,
        gem_name,
        gem_version,
        srcs,
        **kwargs):
    _zip_name = "%s-%s" % (gem_name, gem_version)
    _gemspec_name = name + ".gemspec"

    gemspec(
        name = _gemspec_name,
        gem_name = gem_name,
        gem_version = gem_version,
        srcs = srcs,
        **kwargs
    )

    pkg_zip(
        name = _zip_name,
        srcs = srcs + [":" + _gemspec_name],
        strip_prefix = "./",
    )

    native.alias(
        name = name,
        actual = ":" + _zip_name,
        visibility = ["//visibility:public"],
    )
