load(
    ":providers.bzl",
    "RubyLibrary",
)

def _transitive_srcs(deps):
  transitive_srcs = depset()
  data_files = depset()
  default_files = depset()
  for d in deps:
    if RubyLibrary in d:
      transitive_srcs += d[RubyLibrary].transitive_ruby_srcs
    data_files += d[DefaultInfo].data_runfiles.files
    default_files += d[DefaultInfo].default_runfiles.files

  return struct(
      srcs = transitive_srcs,
      data_files = data_files,
      default_files = default_files
   )

def transitive_deps(ctx, extra_files=[], extra_deps=[]):
  """Calculates transitive sets of args.

  Calculates the transitive sets for ruby sources, data runfiles,
  include flags and runtime flags from the srcs, data and deps attributes
  in the context.
  Also adds extra_deps to the roots of the traversal.

  Args:
    ctx: a ctx object for a ruby_library or a ruby_binary rule.
    extra_deps: a list of Target objects.
  """
  deps = _transitive_srcs(ctx.attr.deps + extra_deps)
  files = depset(extra_files) + ctx.files.srcs
  default_files = ctx.runfiles(
      files = files.to_list(),
      transitive_files = deps.default_files,
      collect_default = True,
  )
  data_files = ctx.runfiles(
      files = ctx.files.data,
      transitive_files = deps.data_files,
      collect_data = True,
  )
  return struct(
      srcs = deps.srcs,
      default_files = default_files,
      data_files = data_files,
  )

