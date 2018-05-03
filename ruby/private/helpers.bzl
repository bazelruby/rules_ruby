load(
    ":providers.bzl",
    "RubyLibrary",
)

def transitive_deps(deps):
  transitive_srcs = depset()
  data_files = depset()
  for d in deps:
    if RubyLibrary in d:
      transitive_srcs += d[RubyLibrary].transitive_ruby_srcs
    data_files += d[DefaultInfo].data_runfiles.files

  return struct(
      transitive_srcs = transitive_srcs,
      data_files = data_files,
   )
