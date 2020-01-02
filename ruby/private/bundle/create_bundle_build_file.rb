#!/usr/bin/env ruby
# frozen_string_literal: true

TEMPLATE = 'load(
  "{workspace_name}//ruby:defs.bzl",
  "ruby_library",
)

package(default_visibility = ["//visibility:public"])

#exports_files(
#    {binaries},
#    visibility = ["//visibility:public"],
#)
#
#filegroup(
#  name = "libs",
#  srcs = glob(["lib/**/*"]),
#  data = [":libs"],
#)
#
#
#filegroup(
#  name = "binstubs",
#  srcs = glob(["bin/**/*"]),
#  data = [":libs"],
#)

ruby_library(
  name = "bundler_setup",
  srcs = ["lib/bundler/setup.rb"],
  visibility = ["//visibility:private"],
)

ruby_library(
  name = "bundler",
  srcs = glob(
    include = [
      "bundler/**/*",
    ],
  ),
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
      "bin/*"
    ],
    exclude = {exclude},
  ),
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/lib/bundler/setup.rb"],
)
'

BIN_TEMPLATE = '
exports_files(
    {binaries},
    visibility = ["//visibility:public"],
)
'

require 'bundler'
require 'json'
require 'stringio'

# This method scans the contents of the Gemfile.lock and if it finds BUNDLED WITH
# it strips that line + the line below it, so that any version of bundler would work.
def remove_bundler_version!(gemfile_lock_file)
  contents = File.read(gemfile_lock_file)
  return unless contents =~ /BUNDLED WITH/

  temp_lock_file = "#{gemfile_lock_file}.no-bundle-version"
  system %(sed -n '/BUNDLED WITH/q;p' "#{gemfile_lock_file}" > #{temp_lock_file})
  ::FileUtils.rm_f(gemfile_lock_file) if File.symlink?(gemfile_lock_file) # it's just a symlink
  ::FileUtils.move(temp_lock_file, gemfile_lock_file, force: true)
end

def ruby_version(ruby_version = RUBY_VERSION)
  @ruby_version ||= (ruby_version.split('.')[0..1] << 0).join('.')
end

def create_bundle_build_file(build_out_file, lock_file, repo_name, excludes, workspace_name)
  template_out = StringIO.new

  bin_folder = File.expand_path('bin', __dir__)
  binaries   = Dir.glob("#{bin_folder}/*").map { |binary| 'bin/' + File.basename(binary) if File.executable?(binary) }

  template_out.puts TEMPLATE
    .gsub('{workspace_name}', workspace_name)
    .gsub('{repo_name}', repo_name)
    .gsub('{ruby_version}', ruby_version)
    .gsub('{binaries}', binaries.to_s)

  # strip bundler version so we can process this file
  remove_bundler_version!(lock_file)

  # Append to the end specific gem libraries and dependencies
  bundle = Bundler::LockfileParser.new(Bundler.read_file(lock_file))

  bundle.specs.each { |spec|
    deps = spec.dependencies.map(&:name)
    deps += [':bundler_setup']

    exclude_array = excludes[spec.name] || []
    # We want to exclude files and folder with spaces in them
    exclude_array += ['**/* *.*', '**/* */*']

    template_out.puts GEM_TEMPLATE
      .gsub('{exclude}', exclude_array.to_s)
      .gsub('{name}', spec.name)
      .gsub('{version}', spec.version.to_s)
      .gsub('{deps}', deps.to_s)
      .gsub('{repo_name}', repo_name)
      .gsub('{ruby_version}', ruby_version)
  }

  ::File.open(build_out_file, 'w') { |f| f.puts template_out.string }

  #::File.open(File.dirname(build_out_file) + '/bin/BUILD.bazel', 'w') { |f| f.puts BIN_TEMPLATE.gsub('{binaries}', binaries.to_s) }
end

# ruby ./create_bundle_build_file.rb "BUILD.bazel" "Gemfile.lock" "repo_name" "[]" "wsp_name"
if $0 == __FILE__
  if ARGV.length != 5
    warn("USAGE: #{$0} BUILD.bazel Gemfile.lock repo-name [excludes-json] workspace-name")
    exit(1)
  end

  build_out_file, lock_file, repo_name, excludes, workspace_name, * = *ARGV

  create_bundle_build_file(build_out_file, lock_file, repo_name, JSON.parse(excludes), workspace_name)
end
