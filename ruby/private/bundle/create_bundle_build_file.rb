#!/usr/bin/env ruby
# frozen_string_literal: true

BUILD_HEADER = <<~MAIN_TEMPLATE
  load(
    "{workspace_name}//ruby:defs.bzl",
    "ruby_library",
  )

  package(default_visibility = ["//visibility:public"])

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
  )

  # PULL EACH GEM INDIVIDUALLY
MAIN_TEMPLATE

GEM_TEMPLATE = <<~GEM_TEMPLATE
  ruby_library(
    name = "{name}",
    srcs = glob(
      include = [
        ".bundle/config",
        {gem_lib_files},
        "{gem_spec}",
        {gem_binaries}
      ],
      exclude = {exclude},
    ),
    deps = {deps},
    includes = [{gem_lib_paths}],
  )
GEM_TEMPLATE

ALL_GEMS = <<~ALL_GEMS
  ruby_library(
    name = "gems",
    srcs = glob([{bundle_lib_files}]) + glob(["bin/*"]),
    includes = {bundle_lib_paths},
  )

  ruby_library(
    name = "bin",
    srcs = glob(["bin/*"]),
    deps = {bundle_with_binaries}
  )
ALL_GEMS

# For ordinary gems, this path is like 'lib/ruby/3.0.0/gems/rspec-3.10.0'.
# For gems with native extension installed via prebuilt packages, the last part of this path can
# contain an OS-specific suffix like 'grpc-1.38.0-universal-darwin' or 'grpc-1.38.0-x86_64-linux'
# instead of 'grpc-1.38.0'.
#
# Since OS platform is unlikely to change between Bazel builds on the same machine,
# `#{gem_name}-#{gem_version}*` would be sufficient to narrow down matches to at most one.
#
# Library path differs across implementations as `lib/ruby` on MRI and `lib/jruby` on JRuby.
GEM_PATH = ->(ruby_version, gem_name, gem_version) do
  Dir.glob("lib/#{RbConfig::CONFIG['RUBY_INSTALL_NAME']}/#{ruby_version}/gems/#{gem_name}-#{gem_version}*").first
end

# For ordinary gems, this path is like 'lib/ruby/3.0.0/specifications/rspec-3.10.0.gemspec'.
# For gems with native extension installed via prebuilt packages, the last part of this path can
# contain an OS-specific suffix like 'grpc-1.38.0-universal-darwin.gemspec' or
# 'grpc-1.38.0-x86_64-linux.gemspec' instead of 'grpc-1.38.0.gemspec'.
#
# Since OS platform is unlikely to change between Bazel builds on the same machine,
# `#{gem_name}-#{gem_version}*.gemspec` would be sufficient to narrow down matches to at most one.
#
# Library path differs across implementations as `lib/ruby` on MRI and `lib/jruby` on JRuby.
SPEC_PATH = ->(ruby_version, gem_name, gem_version) do
  Dir.glob("lib/#{RbConfig::CONFIG['RUBY_INSTALL_NAME']}/#{ruby_version}/specifications/#{gem_name}-#{gem_version}*.gemspec").first
end

require 'bundler'
require 'json'
require 'stringio'
require 'fileutils'
require 'tempfile'

# colorization
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  # @formatter:off
  def red;          colorize(31); end

  def green;        colorize(32); end

  def yellow;       colorize(33); end

  def blue;         colorize(34); end

  def pink;         colorize(35); end

  def light_blue;   colorize(36); end

  def orange;       colorize(52); end
  # @formatter:on
end

class Buildifier
  attr_reader :build_file, :output_file

  # @formatter:off
  class BuildifierError < StandardError; end

  class BuildifierNotFoundError < BuildifierError; end

  class BuildifierFailedError < BuildifierError; end

  class BuildifierNoBuildFileError < BuildifierError; end
  # @formatter:on

  def initialize(build_file)
    @build_file = build_file

    # For capturing buildifier output
    @output_file = ::Tempfile.new("/tmp/#{File.dirname(File.absolute_path(build_file))}/#{build_file}.stdout").path
  end

  def buildify!
    raise BuildifierNoBuildFileError, 'Can\'t find the BUILD file' unless File.exist?(build_file)

    # see if we can find buildifier on the filesystem
    buildifier = `bash -c 'command -v buildifier'`.strip

    raise BuildifierNotFoundError, 'Can\'t find buildifier' unless buildifier && File.executable?(buildifier)

    command = "#{buildifier} -v #{File.absolute_path(build_file)}"
    system("/usr/bin/env bash -c '#{command} 1>#{output_file} 2>&1'")
    code = $?

    return unless File.exist?(output_file)

    output = File.read(output_file).strip.gsub(Dir.pwd, '.').yellow
    begin
      FileUtils.rm_f(output_file)
    rescue StandardError
      nil
    end

    if code == 0
      puts 'Buildifier gave 👍 '.green + (output ? " and said: #{output}" : '')
    else
      raise BuildifierFailedError,
            "Generated BUILD file failed buildifier, with error:\n\n#{output.yellow}\n\n".red
    end
  end
end

class BundleBuildFileGenerator
  attr_reader :workspace_name,
              :repo_name,
              :build_file,
              :gemfile_lock,
              :includes,
              :excludes,
              :ruby_version

  DEFAULT_EXCLUDES = ['**/* *.*', '**/* */*'].freeze

  EXCLUDED_EXECUTABLES = %w(console setup).freeze

  def initialize(workspace_name:,
                 repo_name:,
                 build_file: 'BUILD.bazel',
                 gemfile_lock: 'Gemfile.lock',
                 includes: nil,
                 excludes: nil)
    @workspace_name = workspace_name
    @repo_name      = repo_name
    @build_file     = build_file
    @gemfile_lock   = gemfile_lock
    @includes       = includes
    @excludes       = excludes
    # This attribute returns 0 as the third minor version number, which happens to be
    # what Ruby uses in the PATH to gems, eg. ruby 2.6.5 would have a folder called
    # ruby/2.6.0/gems for all minor versions of 2.6.*
    @ruby_version ||= (RUBY_VERSION.split('.')[0..1] << 0).join('.')
  end

  def generate!
    # when we append to a string many times, using StringIO is more efficient.
    template_out = StringIO.new
    template_out.puts BUILD_HEADER
                        .gsub('{workspace_name}', workspace_name)
                        .gsub('{repo_name}', repo_name)
                        .gsub('{ruby_version}', ruby_version)
                        .gsub('{bundler_setup}', bundler_setup_require)

    # strip bundler version so we can process this file
    remove_bundler_version!

    # Append to the end specific gem libraries and dependencies
    bundle           = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock))
    bundle_lib_paths = []
    bundle_binaries  = {} # gem-name => [ gem's binaries ], ...
    gems             = bundle.specs.map(&:name)

    bundle.specs.each { |spec| register_gem(spec, template_out, bundle_lib_paths, bundle_binaries) }

    template_out.puts ALL_GEMS
                        .gsub('{bundle_lib_files}', to_flat_string(bundle_lib_paths.map { |p| "#{p}/**/*" }))
                        .gsub('{bundle_with_binaries}', bundle_binaries.keys.map { |g| ":#{g}" }.to_s)
                        .gsub('{bundle_binaries}', bundle_binaries.values.flatten.to_s)
                        .gsub('{bundle_lib_paths}', bundle_lib_paths.to_s)
                        .gsub('{bundler_setup}', bundler_setup_require)
                        .gsub('{bundle_deps}', gems.map { |g| ":#{g}" }.to_s)
                        .gsub('{exclude}', DEFAULT_EXCLUDES.to_s)

    ::File.open(build_file, 'w') { |f| f.puts template_out.string }
  end

  private

  def bundler_setup_require
    @bundler_setup_require ||= "-r#{runfiles_path('lib/bundler/setup.rb')}"
  end

  def runfiles_path(path)
    "${RUNFILES_DIR}/#{repo_name}/#{path}"
  end

  # This method scans the contents of the Gemfile.lock and if it finds BUNDLED WITH
  # it strips that line + the line below it, so that any version of bundler would work.
  def remove_bundler_version!
    contents = File.read(gemfile_lock)
    return unless contents =~ /BUNDLED WITH/

    temp_gemfile_lock = "#{gemfile_lock}.no-bundle-version"
    system %(sed -n '/BUNDLED WITH/q;p' "#{gemfile_lock}" > #{temp_gemfile_lock})
    ::FileUtils.rm_f(gemfile_lock) if File.symlink?(gemfile_lock) # it's just a symlink
    ::FileUtils.move(temp_gemfile_lock, gemfile_lock, force: true)
  end

  def register_gem(spec, template_out, bundle_lib_paths, bundle_binaries)
    # Do not register local gems
    return if spec.source.path?

    gem_path = GEM_PATH[ruby_version, spec.name, spec.version]
    spec_path = SPEC_PATH[ruby_version, spec.name, spec.version]
    base_dir = "lib/ruby/#{ruby_version}"

    # paths to register to $LOAD_PATH
    require_paths = Gem::StubSpecification.gemspec_stub(spec_path, base_dir, "#{base_dir}/gems").require_paths
    # Usually, registering the directory paths listed in the `require_paths` of gemspecs is sufficient, but
    # some gems also require additional paths to be included in the load paths.
    require_paths += include_array(spec.name)
    gem_lib_paths = require_paths.map { |require_path| File.join(gem_path, require_path) }
    bundle_lib_paths.push(*gem_lib_paths)

    # paths to search for executables
    gem_binaries               = find_bundle_binaries(gem_path)
    bundle_binaries[spec.name] = gem_binaries unless gem_binaries.nil? || gem_binaries.empty?

    deps = spec.dependencies.map { |d| ":#{d.name}" }

    warn("registering gem #{spec.name} with binaries: #{gem_binaries}") if bundle_binaries.key?(spec.name)

    template_out.puts GEM_TEMPLATE
                        .gsub('{gem_lib_paths}', to_flat_string(gem_lib_paths))
                        .gsub('{gem_lib_files}', to_flat_string(gem_lib_paths.map { |p| "#{p}/**/*" }))
                        .gsub('{gem_spec}', spec_path)
                        .gsub('{gem_binaries}', to_flat_string(gem_binaries))
                        .gsub('{exclude}', exclude_array(spec.name).to_s)
                        .gsub('{name}', spec.name)
                        .gsub('{version}', spec.version.to_s)
                        .gsub('{deps}', deps.to_s)
                        .gsub('{repo_name}', repo_name)
                        .gsub('{ruby_version}', ruby_version)
                        .gsub('{bundler_setup}', bundler_setup_require)
  end

  def find_bundle_binaries(gem_path)
    gem_bin_paths = %W(#{gem_path}/bin #{gem_path}/exe)

    gem_bin_paths
      .map do |bin_path|
      Dir # grab all files under bin/ and exe/ inside the gem folder
        .glob("#{bin_path}/*") # convert to File object
        .map { |b| f = File.new(b); File.executable?(f) ? f : nil }
        .compact # remove non-executables, take basename, minus binary defaults
        .map { |f| File.basename(f.path) } - EXCLUDED_EXECUTABLES # that bundler installs with bundle gem <name
    end.flatten
      .compact
      .sort
      .map { |binary| "bin/#{binary}" }
  end

  def include_array(gem_name)
    (includes[gem_name] || [])
  end

  def exclude_array(gem_name)
    (excludes[gem_name] || []) + DEFAULT_EXCLUDES
  end

  def to_flat_string(array)
    array.to_s.gsub(/[\[\]]/, '')
  end
end

# ruby ./create_bundle_build_file.rb "BUILD.bazel" "Gemfile.lock" "repo_name" "{}" "{}" "wsp_name"
if $0 == __FILE__
  if ARGV.length != 6
    warn("USAGE: #{$0} BUILD.bazel Gemfile.lock repo-name {includes-json} {excludes-json} workspace-name".orange)
    exit(1)
  end

  build_file, gemfile_lock, repo_name, includes, excludes, workspace_name, * = *ARGV

  BundleBuildFileGenerator.new(build_file:     build_file,
                               gemfile_lock:   gemfile_lock,
                               repo_name:      repo_name,
                               includes:       JSON.parse(includes),
                               excludes:       JSON.parse(excludes),
                               workspace_name: workspace_name).generate!

  begin
    Buildifier.new(build_file).buildify!
    puts("Buildifier successful on file #{build_file} ")
  rescue Buildifier::BuildifierError => e
    warn("ERROR running buildifier on the generated build file [#{build_file}] ➔ #{e.message.orange}")
  end
end
