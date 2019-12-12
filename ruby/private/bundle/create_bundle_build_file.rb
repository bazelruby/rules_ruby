# frozen_string_literal: true

TEMPLATE = 'load(
  "{workspace_name}//ruby:defs.bzl",
  "ruby_library",
)


package(default_visibility = ["//visibility:public"])

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":libs"],
)

ruby_library(
  name = "bundler_setup",
  srcs = ["lib/bundler/setup.rb"],
  visibility = ["//visibility:private"],
)

# DEPRECATED: use :all instead
ruby_library(
  name = "libs",
  srcs = glob(
    include = [
      "lib/ruby/{ruby_version}/gems/*/**/*",
      "lib/ruby/{ruby_version}/bin/**/*",
    ],
    exclude = {exclude},
  ),
  deps = [":bundler_setup"],
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/lib/bundler/setup.rb"],
)

# PULL EACH GEM INDIVIDUALLY
'

GEM_TEMPLATE = '
ruby_library(
  name = "{name}",
  srcs = glob(
    include = [
      "lib/ruby/{ruby_version}/gems/{name}-{version}/**/*",
      # TODO scope down included bin files
      "lib/ruby/{ruby_version}/bin/**/*",
    ],
    exclude = {exclude},
  ),
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/lib/bundler/setup.rb"],
)

'

ALL_TEMPLATE = '
ruby_library(
  name = "all",
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/lib/bundler/setup.rb"],
)
'
require "bundler"

def create_bundle_build_file(build_out_file, lock_file, repo_name, excludes, workspace_name)
  # TODO: properly calculate path/ruby version here
  # ruby_version = RUBY_VERSION # doesnt work because verion is 2.5.5 path is 2.5.0
  ruby_version = "*"

  template_out = TEMPLATE.gsub("{workspace_name}", workspace_name)
                         .gsub("{exclude}", excludes)
                         .gsub("{repo_name}", repo_name)
                         .gsub("{ruby_version}", ruby_version)

  # Append to the end specific gem libraries and dependencies
  bundle = Bundler::LockfileParser.new(Bundler.read_file(lock_file))

  bundle.specs.each { |spec|
    deps = spec.dependencies.map(&:name)
    deps += [":bundler_setup"]
    template_out += GEM_TEMPLATE.gsub("{exclude}", excludes)
                                .gsub("{name}", spec.name)
                                .gsub("{version}", spec.version.to_s)
                                .gsub("{deps}", deps.to_s)
                                .gsub("{repo_name}", repo_name)
                                .gsub("{ruby_version}", ruby_version)
  }

  # Append collection of all gems
  template_out += ALL_TEMPLATE.gsub("{repo_name}", repo_name)
                              .gsub("{deps}", ([":bundler_setup"] + bundle.specs.map(&:name)).to_s)

  # Write the actual BUILD file
  ::File.open(build_out_file, 'w') { |f|
    f.puts template_out
  }
end

# ruby ./create_bundle_build_file.rb "BUILD.bazel" "Gemfile.lock" "repo_name" "[]" "wsp_name"
if $0 == __FILE__
  if ARGV.length != 5
    fmt.Println("BUILD FILE ARGS not 5")
    exit(1)
  end

  build_out_file = ARGV[0]
  lock_file = ARGV[1]
  repo_name = ARGV[2]
  excludes = ARGV[3]
  workspace_name = ARGV[4]

  create_bundle_build_file(build_out_file, lock_file, repo_name, excludes, workspace_name)
end
