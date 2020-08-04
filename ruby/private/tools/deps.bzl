load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "//ruby/private:providers.bzl",
    "RubyLibraryInfo",
)

def _transitive_srcs(deps):
    return struct(
        srcs = [d[RubyLibraryInfo].transitive_ruby_srcs for d in deps if RubyLibraryInfo in d],
        incpaths = [d[RubyLibraryInfo].ruby_incpaths for d in deps if RubyLibraryInfo in d],
        rubyopt = [d[RubyLibraryInfo].rubyopt for d in deps if RubyLibraryInfo in d],
        data_files = [d[DefaultInfo].data_runfiles.files for d in deps],
        default_files = [d[DefaultInfo].default_runfiles.files for d in deps],
    )

def transitive_deps(ctx, extra_files = [], extra_deps = []):
    """
    Calculates transitive sets of args.

    Calculates the transitive sets for ruby sources, data runfiles,
    include flags and runtime flags from the srcs, data and deps attributes
    in the context.
    Also adds extra_deps to the roots of the traversal.

    Args:
      ctx: a ctx object for a ruby_library or a ruby_binary rule.
      extra_files: a list of File objects to be added to the default_files
      extra_deps: a list of Target objects.
    Returns:
        struct
    """
    deps = _transitive_srcs(ctx.attr.deps + extra_deps)
    files = depset(extra_files + ctx.files.srcs)
    default_files = ctx.runfiles(
        files = files.to_list(),
        transitive_files = depset(transitive = deps.default_files),
        collect_default = True,
    )
    data_files = ctx.runfiles(
        files = ctx.files.data,
        transitive_files = depset(transitive = deps.data_files),
        collect_data = True,
    )
    workspace = ctx.label.workspace_name or ctx.workspace_name
    includes = [
        paths.join(workspace, inc)
        for inc in ctx.attr.includes
    ]
    return struct(
        srcs = depset(
            direct = ctx.files.srcs,
            transitive = deps.srcs,
        ),
        incpaths = depset(
            direct = includes,
            transitive = deps.incpaths,
            order = "topological",
        ),
        rubyopt = depset(
            direct = ctx.attr.rubyopt,
            transitive = deps.rubyopt,
            order = "topological",
        ),
        default_files = default_files,
        data_files = data_files,
    )
