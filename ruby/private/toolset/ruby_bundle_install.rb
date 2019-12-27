#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'
require 'json'
require 'stringio'
require 'rubygems'
require 'optparse'
require 'ostruct'
require 'tempfile'
require 'fileutils'

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
  # This class generates the Bundle's workspace together with the BUILD file.
  # This BUILD file will include the bundler itself at the top, and the each
  # gem mentioned in the lock file below.
  #
  # NOTE: this class currently DOES NOT actually install any gems.
  class BundleInstall
    include RulesRuby::Helpers
    Helpers.prog_name = 'generate-bundle-build-file'

    # This is the list of our attributes that are set via command line flags
    # and passed in as a hash. We use shortcuts to mass-assign them to keep it DRY.
    BUNDLE_ATTRS = [
      :buildifier, # if True, or a String (path) forces to run buildifier on generated file
      :bundle_path, # relative path where the bundle is installed, eg 'vendor/bundle'
      :excludes, # a hash where keys are gem names, and values are dir globs to exclude
      :gemfile_lock_file, # name and optional path of the Gemfile.lock to be read
      :generated_build_file, # path or name of the generated build file
      :repo_name, # name of the current repo, used as a subdirectory under $RUNFILES_DIR
      :verbose, # if true, extra info is printed, including stack traces
      :workspace_name,
    ].freeze

    BUNDLE_HASH_ATTRS = Hash[BUNDLE_ATTRS.collect { |item| [item, nil] }]
    attr_reader(*BUNDLE_ATTRS)

    def initialize(**opts)
      args = []
      BUNDLE_ATTRS.each do |attr|
        instance_variable_set("@#{attr}", opts[attr])
        args << attr
      end

      diff = opts.keys - args
      raise ArgumentError, "Invalid arguments: #{diff}" unless diff.empty?
    end

    # The one and only public method of this class.
    def generate_bazel_build_file
      puts
      output_stream.puts render_template(templates.bundler, attribute_map_global)
      remove_bundler_version!
      bundle_lock_file = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock_file))
      gem_count        = bundle_lock_file.specs.size

      inf "began generating BUILD file, total of #{gem_count} gems to add..."
      bundle_lock_file.specs.each(&method(:generate_gems_targets))
      inf "bundler-generated BUILD file of total length: #{output_stream.string.size}"

      # Now we should save it, yeah?
      save_build_file!

      # Once it's saved, let's run buildifier on it, because why not.
      if run_buildifier?
        inf 'Running buildifier on the file...'
        begin
          run_buildifier!
        rescue StandardError => e
          wrn("Error running Buildifier on #{generated_build_file.red}: #{e.message.yellow}")
        end
      end

      inf 'OK (installed '.green + gem_count.to_s.yellow + ' gems)'.green
    end

    private

    def remove_bundler_version!
      contents = File.read(gemfile_lock_file)
      if contents =~ /BUNDLED WITH/
        FileUtils.cp(gemfile_lock_file, "#{gemfile_lock_file}.backup")
        system %(sed -n '/BUNDLED WITH/q;p' "#{gemfile_lock_file}.backup" > #{gemfile_lock_file})
      end
    end

    def save_build_file!
      inf "writing BUILD contents into #{generated_build_file.yellow}"

      # Write the actual BUILD file
      ::File.open(generated_build_file, 'w') { |f|
        f.puts output_stream.string
      }
    end

    def attribute_map_global
      @attribute_map_global ||= {
        ruby_version:   ruby_version,
        repo_name:      repo_name,
        bundle_path:    bundle_path,
        workspace_name: workspace_name,
      }
    end

    def gem_path(spec)
      "#{bundle_path}/ruby/#{ruby_version}/gems/#{spec.name}-#{spec.version}"
    end

    def attribute_map_for_gem(spec)
      # We want to exclude files and folder with spaces in them
      exclude_array = (excludes[spec.name] || []) + ['**/* *.*', '**/* */*']

      {
        exclude:  exclude_array.to_s,
        name:     spec.name,
        version:  spec.version.to_s,
        deps:     spec_deps(spec).to_s,
        gem_path: gem_path(spec),
      }.merge(attribute_map_global)
    end

    def generate_gems_targets(spec)
      inf "Adding gem #{spec.name.to_s.red} v#{spec.version.to_s.green}..."

      output_stream.puts(
        render_template(
          templates.gem_library,
          attribute_map_for_gem(spec)
        )
      )

      gem_executables(spec, gem_path(spec)).each do |binary|
        output_stream.puts(
          render_template(
            templates.gem_binary,
            attribute_map_for_gem(spec).merge(label_name: binary.label_name, bin_path: binary.bin_path)
          )
        )
      end
    end

    def spec_deps(spec)
      [].tap do |d|
        d << spec.dependencies.map(&:name)
        d << ':bundler_setup'
        d.flatten!
      end
    end

    def render_template(template, attribute_map)
      attribute_map.inject(template) { |t, (key, value)| t.gsub("{#{key}}", value) }
    end

    def run_buildifier?
      buildifier != false
    end

    def run_buildifier!
      build_file = generated_build_file
      temp_path  = "/tmp/#{workspace_name}/#{repo_name}"
      buildifier = `bash -c 'command -v buildifier'`.strip

      raise BuildifierError, 'Can\'t find buildifier' unless buildifier && File.executable?(buildifier)
      raise BuildifierError, 'Can\'t find the BUILD file' unless File.exist?(build_file)

      output_file = ::Tempfile.new("#{temp_path}/#{generated_build_file}.output_file").path

      command = "#{buildifier} -v #{File.absolute_path(build_file)}"
      system("/usr/bin/env bash -c '#{command} 1>#{output_file} 2>&1'")
      code = $?

      output = File.read(output_file).strip.gsub(Dir.pwd, '.').yellow
      inf "buildifier said: #{output}" if output

      if code == 0
        inf 'Buildifier gave 👍'.green
      else
        raise BuildifierError,
              'Generated BUILD file failed buildifier, with error — '.red +
              (verbose ? File.read(output_file).yellow : output_file.to_s.yellow)
      end
    end

    BinTuple = Struct.new(:bin_path, :label_name)

    # Finds any executables under the gem path and exposes them
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

    def output_stream
      @output_stream ||= StringIO.new
    end

    def templates
      BuildTemplates.templates
    end

    # given a path such as
    # /Users/kig/.rbenv/versions/2.5.3/lib/ruby/gems/2.5.0/gems/irb-1.0.0/exe/irb
    # returns a tuple, with the path and a label named ':irb-binary
    def binary_label(binary_path)
      "#{File.basename(binary_path)}-binary"
    end
  end

  BuildTemplates = Struct.new(:bundler, :gem_library, :gem_binary) do
    def valid?
      [bundler, gem_library, gem_binary].all? { |t| t.length > 100 }
    end

    class << self
      attr_reader :templates

      def load_templates!
        return @templates if @templates&.valid?

        @templates ||= new

        templates.bundler     = File.read(File.expand_path('../BUILD.bundler.tpl', __FILE__))
        templates.gem_library = File.read(File.expand_path('../BUILD.gem.library.tpl', __FILE__))
        templates.gem_binary  = File.read(File.expand_path('../BUILD.gem.binary.tpl', __FILE__))

        raise ArgumentError, 'Unable to parse BUILD file templates as DATA' unless templates.valid?
      end
    end
  end

  BuildTemplates.load_templates!

  # —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
  # Arguments Parsing
  # —————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

  class Parser
    USAGE = <<~HELP
      #{'USAGE'.help_header}
        ruby_bundle_install.rb [options]

      #{'DESCRIPTION'.help_header}
        This utility reads a Gemfile.lock passed in as an argument,
        and generates Bazel Build file for the Bundler (separately),
        as well as for each Gem in the Gemfile.lock (including transitive
        dependencies).

      #{'OPTIONS'.help_header}
    HELP

    class << self
      def parse_argv(argv = ARGV.dup)
        OpenStruct.new.tap do |options|
          # Defaults
          options.buildifier           = true
          options.bundle_path          = BUNDLE_PATH
          options.excludes             = {}
          options.gemfile_lock_file    = DEFAULT_GEMFILE_LOCK
          options.generated_build_file = DEFAULT_BUILD_FILE
          options.verbose              = false
          ::OptionParser.new do |opts|
            opts.banner = Parser::USAGE
            opts.separator ' '
            opts.on('-l', '--gemfile-lock=FILE', 'Path to the Gemfile.lock') do |n|
              raise GemfileNotFound, "Gemfile.lock #{n} is not a valid file." unless File.exist?(n)

              options.gemfile_lock_file = n
            end

            opts.on('-o', '--output_file=FILE', 'Path to the generated BUILD file') do |n|
              options.generated_build_file = n
            end

            opts.on('-B', '--skip-buildifier', 'Do not run buildifier on the generated file.') do |*|
              options.buildifier = false
            end

            opts.on('-r', '--repo=NAME', 'Name of the repository') do |n|
              options.repo_name = n
            end

            opts.on('-w', '--workspace=NAME', 'Name of the workspace') do |n|
              options.workspace_name = n
            end

            opts.on('-p', '--bundle-path=PATH', 'Where to install Gems relative to current',
                    'directory. Defaults to ' + BUNDLE_PATH) do |n|
              options.bundle_path = n
            end

            opts.on('-e', '--excludes=JSON', 'JSON formatted hash with keys as gem names,',
                    'and values as arrays of glob patterns.') do |n|
              options.excludes = {}
              options.excludes.merge!(JSON.parse(n))
            rescue JSON::ParserError => e
              warn "JSON provided throws error: #{e.message}"
              exit 1
            end

            opts.on('-v', '--verbose', 'Print verbose info') do |_n|
              options.verbose = true
            end

            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              exit
            end
            opts.separator ' '
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
#         -p  vendor/bundle
#         "[]"

if $0 == __FILE__
  verbose = !(ARGV & %w(-v --verbose)).empty?
  begin
    options = RulesRuby::Parser.parse_argv(ARGV.empty? ? ['-h'] : ARGV.dup)
    pp options.to_h if options.verbose
    RulesRuby::BundleInstall.new(**options.to_h).generate_bazel_build_file
  rescue StandardError => e
    puts 'ERROR — '.red + e.message.yellow
    if verbose
      puts 'STACKTRACE: '
      puts e.backtrace.join("\n").red
    end
  end
end
