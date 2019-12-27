
# Binary Rule for Gem #{name}

ruby_binary(
  name = "{label_name}",  # eg, rspec/bin/rspec
  main = "{bin_path}",
  deps = [":{name}"] + {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/lib/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)
