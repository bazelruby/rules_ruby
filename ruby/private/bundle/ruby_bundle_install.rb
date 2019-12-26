# frozen_string_literal: true

require 'bundler'
require 'json'
require 'stringio'
require 'rubygems'
require 'optparse'
require 'ostruct'

require_relative 'ruby_helpers'

# README PLEASE
#
# NOTE: this file does not run bundle install, that happens in Bazel.
#
# What this file does is parse the Gemfile.lock file, and generating a
# single aggregated BUILD.bazel file that contains both the Bundler itself
# and the install gems as ruby_libraries and sometimes ruby_binaries.
#
# You can later reference the sources by using the label you gave to the
# ruby_bundle_install rule.
#
module RulesRuby
  DIVIDER              = '——————————————————————————————————————————————————————————————————————'
  BUNDLE_PATH          = 'vendor/bundle'
  DEFAULT_GEMFILE_LOCK = 'Gemfile.lock'
  DEFAULT_BUILD_FILE   = 'BUILD.bazel'

  @templates = Struct.new(:bundler, :gem, :gem_binary) do
    def valid?
      bundler && gem && gem_binary
    end
  end.new

  class << self
    attr_reader :templates

    def load_templates!
      return unless templates

      bundler_build_file, gem_build_file, gem_binary_file = DATA.read.split(DIVIDER)

      templates.bundler    = bundler_build_file
      templates.gem        = gem_build_file
      templates.gem_binary = gem_binary_file

      raise ArgumentError, 'Unable to parse BUILD file templates as DATA' unless templates.valid?
    end
  end

  load_templates!

  class BundleInstall
    # This method generates the BUILD file for Bundler' s own mini - workspace.
    # This BUILD file will include the bundler itself at the top, and the each
    # gem mentioned in the lock file below.
    attr_reader :repo_name, :excludes, :workspace_name, :generated_build_file,
                :gemfile_lock_file, :bundle_path

    include RulesRuby::Helpers

    def initialize(
      repo_name:,
      excludes: {},
      workspace_name:,
      generated_build_file: DEFAULT_BUILD_FILE,
      gemfile_lock_file: DEFAULT_GEMFILE_LOCK,
      bundle_path: BUNDLE_PATH
    )

      @repo_name            = repo_name
      @excludes             = excludes
      @workspace_name       = workspace_name
      @generated_build_file = generated_build_file
      @gemfile_lock_file    = gemfile_lock_file
      @bundle_path          = bundle_path
    end

    def render_build_file!
      template_out.puts templates.bundler
                                 .gsub('{workspace_name}', workspace_name)
                                 .gsub('{repo_name}', repo_name)
                                 .gsub('{ruby_version}', ruby_version)

      # Append to the end specific gem libraries and dependencies
      bundle_lock_file = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock_file))

      bundle_lock_file.specs.each do |spec|
        deps = [].tap do |d|
          d << spec.dependencies.map(&:name)
          d << ':bundler_setup'
          d.flatten!
        end

        # We want to exclude files and folder with spaces in them
        exclude_array = (excludes[spec.name] || []) + ['**/* *.*', '**/* */*']

        gem_path = "#{bundle_path}/ruby/#{ruby_version}/gems/#{spec.name}-#{spec.version}"

        template_out.puts templates.gem
                                   .gsub('{exclude}', exclude_array.to_s)
                                   .gsub('{name}', spec.name)
                                   .gsub('{version}', spec.version.to_s)
                                   .gsub('{deps}', deps.to_s)
                                   .gsub('{repo_name}', repo_name)
                                   .gsub('{ruby_version}', ruby_version)
                                   .gsub('{gem_path}', gem_path)
                                   .gsub('{bundle_path}', bundle_path)

        gem_executables(spec, gem_path).each do |binary|
          template_out.puts templates.gem_binary
                                     .gsub('{name}', spec.name)
                                     .gsub('{version}', spec.version.to_s)
                                     .gsub('{deps}', deps.to_s)
                                     .gsub('{repo_name}', repo_name)
                                     .gsub('{label_name}', binary.label_name)
                                     .gsub('{bin_path}', binary.bin_path)
                                     .gsub('{bundle_path}', bundle_path)
        end
      end

      # Write the actual BUILD file
      ::File.open(generated_build_file, 'w') { |f|
        f.puts template_out.string
      }

      run_buildifier!
    end

    def run_buildifier!(build_file = generated_build_file,
                        temp_path = "/tmp/#{workspace_name}/#{repo_name}")

      buildifier = `bash -c 'command -v buildifier'`
      return unless buildifier && File.executable?(buildifier)

      return unless File.exist?(build_file)

      output = Tempfile.new("#{temp_path}/#{generated_build_file}.output").path
      system("set -e ; buildifier #{generated_build_file} 1>#{output} 2>&1")
      code = $?
      if code == 0
        puts 'Generated BUILD.bazel file passed buildifier.'.green
      else
        raise BuildifierError,
              'Generated BUILD file failed buildifier, with error:'.red +
              File.read(OUTPUT).yellow
      end
    end

    BinTuple = Struct.new(:bin_path, :label_name)

    # Finds any executables under the gem path and exploses them
    def gem_executables(_gem_spec, gem_path)
      [].tap do |executables|
        %w(exe bin).each do |bin_dir|
          next unless Dir.exist?("#{gem_path}/#{bin_dir}")

          Dir.glob("#{gem_path}/#{bin_dir}/*").each do |binary|
            next unless File.executable?(binary)

            tuple = BinTuple.new(binary, binary_label(binary))
            executables << tuple
          end
        end
      end
    end

    def template_out
      @template_out ||= StringIO.new
    end

    def templates
      RulesRuby.templates
    end

    # given a path such as
    # /Users/kig/.rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/irb-1.0.0/exe/irb
    # returns a tuple, with the path and a label named ':irb-binary
    def binary_label(binary_path)
      "#{File.basename(binary_path)}-binary"
    end
  end
end

module RulesRuby
  class Parser
    class << self
      def parse_argv(argv = ARGV.dup)
        OpenStruct.new.tap do |options|
          # Defaults
          options.excludes             = {}
          options.gemfile_lock_file    = 'Gemfile.lock'
          options.generated_build_file = 'BUILD.bazel'

          ::OptionParser.new do |opts|
            opts.banner = 'Usage: '.green + $0 + ' [options]'
            opts.separator ''
            opts.separator 'Description:'.green
            opts.separator '  This utility reads Gemfile.lock passed as an argument.'
            opts.separator '  and runs bundle install into the budle prefix folder.' + "\n"
            opts.separator ''
            opts.separator 'Required Arguments:'.green
            opts.on('-l', '--gemfile-lock=FILE', 'Path to the Gemfile.lock') do |n|
              raise GemfileNotFounds, "Gemfile.lock #{n} is not a valid file." unless File.exist?(n)

              options.gemfile_lock_file = n
            end

            opts.on('-o', '--output=FILE', 'Bazel Build output file') do |n|
              options.generated_build_file = n
            end

            opts.on('-r', '--repo=NAME', 'Name of the repository') do |n|
              options.repo_name = n
            end

            opts.on('-w', '--workspace=NAME', 'Name of the workspace') do |n|
              options.workspace_name = n
            end

            opts.on('-p', '--bundle-path=PATH', 'Where to install Gems relative to current',
                    'directory. Defaults to ' + BUNDLE_PATH) do |n|
              options.workspace_name = n
            end

            opts.on('-e', '--excludes=JSON', 'JSON formatted hash with keys as gem names,',
                    'and values as arrays of glob patterns.') do |n|
              options.excludes = {}
              options.excludes.merge!(JSON.parse(n))
            rescue JSON::ParserError => e
              warn "JSON provided throws error: #{e.message}"
              exit 1
            end

            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              exit
            end
          end.parse!(argv)
        end
      end
    end
  end
end

# Running this script:
#
# ruby ./ruby_bundle_install.rb
#         -l  Gemfile.lock \
#         -r  repo_name \
#         -w "workspace_name"
#         -o "BUILD.bazel" \
#         "[]"

if $0 == __FILE__
  options = RulesRuby::Parser.parse_argv(ARGV.empty? ? ['-h'] : ARGV.dup)
  RulesRuby::BundleInstall.new(**options.to_h)
end


__END__

# WARNING: this file is auto-generated and will be replaced
# on every repository rule run.
#
# © 2018-2020 Yuki (@yugui) Sonoda, Graham Jenson, Konstantin Gredeskoul & BazelRuby authors
#
# Distributed under Apache 2.0 LICENSE.
#

load(
  "{workspace_name}//ruby:defs.bzl",
  "ruby_library",
  "ruby_binary",
)

package(default_visibility = ["//visibility:public"])

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":libs"],
)

ruby_library(
  name = "bundler_setup",
  srcs = ["{bundle_path}/bundler/setup.rb"],
  visibility = ["//visibility:private"],
)

ruby_library(
  name = "bundler",
  srcs = glob(
    [
      "bundler/**/*",
    ],
  ),
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/bundler/setup.rb"],
)

——————————————————————————————————————————————————————————————————————

# Build constructs for the gem {name} (#{version})

# exports_files([
#     glob(
#         [
#             "{gem_path}/**/*",
#         ],
#     ),
# ])

filegroup(
  name = "{name}.package",
  srcs =
  glob(
    include = [
      "{gem_path}/**/*",
    ],
    exclude = {exclude},
  ),
  visibility = ["//visibility:public"],
)

ruby_library(
  name = "{name}",
  srcs = [":{name}.package"],
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

ruby_test(
  name = "{name}",
  srcs = [":{name}.package"],
  deps = {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)

——————————————————————————————————————————————————————————————————————

# gem {name} (v{version}) includes executables, so we are exporting them
# to the outside Ruby code.

ruby_binary(
  name = "{label_name}",  # eg, rspec/bin/rspec
  main = "{bin_path}",
  deps = [":{name}"] + {deps},
  rubyopt = ["-r${RUNFILES_DIR}/{repo_name}/{bundle_path}/bundler/setup.rb"],
  visibility = ["//visibility:public"],
)


