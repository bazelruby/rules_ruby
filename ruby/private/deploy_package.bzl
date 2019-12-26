load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")
load(":providers.bzl", "RubyLibrary")
load(
    "//ruby/private/tools:deps.bzl",
    _transitive_deps = "transitive_deps",
)

def _ruby_deploy_package(ctx):
    if not ctx.attr.srcs and not ctx.attr.deps:
        fail("At least srcs or deps must be present")

    deps = _transitive_deps(ctx)
    return [
        DefaultInfo(
            default_runfiles = deps.default_files,
            data_runfiles = deps.data_files,
            files = deps.srcs,
        ),
        RubyLibrary(
            transitive_ruby_srcs = deps.srcs,
            ruby_incpaths = deps.incpaths,
            rubyopt = deps.rubyopt,
        ),
    ]

ruby_deploy_package = rule(
    implementation = _ruby_deploy_package
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "includes": attr.string_list(),
        "rubyopt": attr.string_list(),
        "deps": attr.label_list(
            providers = [RubyLibrary],
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
    },
    toolchains = [TOOLCHAIN_TYPE_NAME],
)


def get_transitive_srcs(srcs, deps):
  """Obtain the source files for a target and its transitive dependencies.

  Args:
    srcs: a list of source files
    deps: a list of targets that are direct dependencies
  Returns:
    a collection of the transitive sources
  """
  return depset(
        srcs,
        transitive = [dep[FooFiles].transitive_sources for dep in deps])

def _foo_library_impl(ctx):
  trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
  return [FooFiles(transitive_sources=trans_srcs)]

foo_library = rule(
    implementation = _foo_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
    },
)

def _foo_binary_impl(ctx):
  foocc = ctx.executable._foocc
  out = ctx.outputs.out
  trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
  srcs_list = trans_srcs.to_list()
  ctx.actions.run(executable = foocc,
                  arguments = [out.path] + [src.path for src in srcs_list],
                  inputs = srcs_list + [foocc],
                  outputs = [out])

foo_binary = rule(
    implementation = _foo_binary_impl,
    attrs = {
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
        "_foocc": attr.label(default=Label("//depsets:foocc"),
                             allow_files=True, executable=True, cfg="host")
    },
    outputs = {"out": "%{name}.out"},
)