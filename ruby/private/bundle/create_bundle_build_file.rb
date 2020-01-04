#!/usr/bin/env ruby
# frozen_string_literal: true

TEMPLATE = <<~MAIN_TEMPLATE
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
    rubyopt = ["{bundler_setup}"],
  )

  # PULL EACH GEM INDIVIDUALLY
MAIN_TEMPLATE

GEM_TEMPLATE = <<~GEM_TEMPLATE
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
    includes = ["lib/ruby/{ruby_version}/gems/{name}-{version}/lib"],
    rubyopt = ["{bundler_setup}"],
  )
GEM_TEMPLATE

ALL_GEMS = <<~ALL_GEMS
  ruby_library(
    name = "gems",
    srcs = glob(
      {gems_lib_files},
    ),
    includes = {gems_lib_paths},
    rubyopt = ["{bundler_setup}"],
  )
ALL_GEMS

GEM_LIB_PATH = ->(ruby_version, gem_name, gem_version) do
  "lib/ruby/#{ruby_version}/gems/#{gem_name}-#{gem_version}/lib"
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

  def orange;       colorize(41); end
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
            'Generated BUILD file failed buildifier, with error — '.red + "\n\n" +
            File.read(output_file).yellow
    end
  end
end

class BundleBuildFileGenerator
  attr_reader :workspace_name,
              :repo_name,
              :build_file,
              :gemfile_lock,
              :excludes,
              :ruby_version

  def initialize(workspace_name:,
                 repo_name:,
                 build_file: 'BUILD.bazel',
                 gemfile_lock: 'Gemfile.lock',
                 excludes: nil)
    @workspace_name = workspace_name
    @repo_name      = repo_name
    @build_file     = build_file
    @gemfile_lock   = gemfile_lock
    @excludes       = excludes
    # This attribute returns 0 as the third minor version number, which happens to be
    # what Ruby uses in the PATH to gems, eg. ruby 2.6.5 would have a folder called
    # ruby/2.6.0/gems for all minor versions of 2.6.*
    @ruby_version ||= (RUBY_VERSION.split('.')[0..1] << 0).join('.')
  end

  def generate!
    # when we append to a string many times, using StringIO is more efficient.
    template_out = StringIO.new

    # In Bazel we want to use __FILE__ because __dir__points to the actual sources, and we are
    # using symlinks here.
    #
    # rubocop:disable Style/ExpandPathArguments
    bin_folder = File.expand_path('../bin', __FILE__)
    binaries   = Dir.glob("#{bin_folder}/*").map do |binary|
      'bin/' + File.basename(binary) if File.executable?(binary)
    end
    # rubocop:enable Style/ExpandPathArguments

    template_out.puts TEMPLATE
                        .gsub('{workspace_name}', workspace_name)
                        .gsub('{repo_name}', repo_name)
                        .gsub('{ruby_version}', ruby_version)
                        .gsub('{binaries}', binaries.to_s)
                        .gsub('{bundler_setup}', bundler_setup_require)

    # strip bundler version so we can process this file
    remove_bundler_version!
    # Append to the end specific gem libraries and dependencies
    bundle        = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock))
    gem_lib_paths = []
    bundle.specs.each { |spec| register_gem(spec, template_out, gem_lib_paths) }

    template_out.puts ALL_GEMS
                        .gsub('{gems_lib_files}', gem_lib_paths.map { |p| "#{p}/**/*.rb" }.to_s)
                        .gsub('{gems_lib_paths}', gem_lib_paths.to_s)
                        .gsub('{bundler_setup}', bundler_setup_require)

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

  def register_gem(spec, template_out, gem_lib_paths)
    gem_lib_paths << GEM_LIB_PATH[ruby_version, spec.name, spec.version]
    deps = spec.dependencies.map { |d| ":#{d.name}" }
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
                        .gsub('{bundler_setup}', bundler_setup_require)
  end
end

# ruby ./create_bundle_build_file.rb "BUILD.bazel" "Gemfile.lock" "repo_name" "[]" "wsp_name"
if $0 == __FILE__
  if ARGV.length != 5
    warn("USAGE: #{$0} BUILD.bazel Gemfile.lock repo-name [excludes-json] workspace-name".orange)
    exit(1)
  end

  build_file, gemfile_lock, repo_name, excludes, workspace_name, * = *ARGV

  BundleBuildFileGenerator.new(build_file:     build_file,
                               gemfile_lock:   gemfile_lock,
                               repo_name:      repo_name,
                               excludes:       JSON.parse(excludes),
                               workspace_name: workspace_name)
                               .generate!

  begin
    Buildifier.new(build_file).buildify!
    puts("Buildifier successful on file #{build_file} ")
  rescue Buildifier::BuildifierError => e
    warn("ERROR running buildifier on the generated build file [#{build_file}] ➔ \n#{e.message.orange}")
  end
end
