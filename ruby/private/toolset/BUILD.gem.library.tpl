
# Main library definition
ruby_library(
  name = "{name}",
  srcs = glob(
    include = [
      "{gem_path}/**/*",
    ],
    exclude = {exclude},
  ),
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/lib/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

# All of the gem's library and executable sources
ruby_library(
  name = "{name}.sources",
  srcs = glob(
    include = [
      "{gem_path}/lib/**/*",
      "{gem_path}/exe/**/*",
    ],
    exclude = {exclude},
  ),
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/lib/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

# File group that includes all files under the gem's installation folder.
filegroup(
  name = "{name}.package",
  srcs = glob(
    include = [
      "{gem_path}/**/*",
    ],
    exclude = {exclude},
  ),
  visibility = ["//visibility:public"],
)

