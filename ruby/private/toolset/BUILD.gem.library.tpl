
# Main library definition
ruby_library(
  name = "{name}",
  srcs = glob(
    include = [
      "{gem_path}/**/*",
    ],
    exclude = {exclude},
    exclude_directories = 0,
  ),
  includes = [ "{gem_path}/lib" ],
  deps = {deps},
  rubyopt = {rubyopts}
)


filegroup(
  name = "{name}.files",
  srcs = glob(
    include = [
      "{gem_path}/**/*",
    ],
    exclude = {exclude},
    exclude_directories = 0,
  ),
)

