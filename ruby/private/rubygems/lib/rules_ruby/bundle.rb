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

require_relative '../rules_ruby'

# README PLEASE
#
# NOTE: this file does not run bundle install, that happens in Bazel.
#
# What this file does is parse the Gemfile.lock file, and generating a
# single aggregated BUILD.bazel file that contains both the Bundler itself
# and the install gems as ruby_libraries and sometimes ruby_binaries.
#
# You can later reference the sources by using the label you gave to the
# ruby_bundle rule.
#
module RulesRuby
  # This class generates the Bundle's workspace together with the BUILD file.
  # This BUILD file will include the bundler itself at the top, and the each
  # gem mentioned in the lock file below.
  #
  # NOTE: this class currently DOES NOT actually install any gems.
  #
  # NOTE: we use StringIO to aggregate all output and then write it to a file
  #       all at once, this is done via the +@output_stream+ variable
  #
  class Bundle
    include RulesRuby::Helpers

    tool_name 'generate-bundle-build-file'

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

    # This is a hash with key a filename (without the path) that's an executable,
    # and the value is the gem name it requires. We'll use that to generate a separate
    # BUILD file inside the `bin` folder.
    attr_reader :binstubs, :gem_prefix

    def initialize(**opts)
      print_header(self)

      args = []
      BUNDLE_ATTRS.each do |attr|
        instance_variable_set("@#{attr}", opts[attr])
        args << attr
      end

      diff = opts.keys - args
      raise ArgumentError, "Invalid arguments: #{diff}" unless diff.empty?

      @gem_prefix = "#{bundle_path}/ruby/#{ruby_version}/gems"
      @binstubs   = {}
    end

    #
    # The one and only public method of this class.
    def generate_bazel_build_file!
      # start with the header
      output_stream.puts render_template(templates.header,
                                         attribute_map_global)

      # Render the first part of the BUILD file, the Bundler itself
      output_stream.puts render_template(templates.bundler,
                                         attribute_map_global)

      binstubs_build_file.puts render_template(templates.header,
                                               attribute_map_global)

      generated_binstub_build_file = File.dirname(generated_build_file) + '/bin/BUILD.bazel'

      # Before we parse the Gemfile, remove the section that freezes bundler version
      remove_bundler_version!

      # Now parse the Gemfile, allowing us loop over gems specs and figure out
      # transient dependencies.
      bundle_lock_file = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock_file))
      gem_count        = bundle_lock_file.specs.size

      bundle_lock_file.specs.each(&method(:generate_gems_targets))
      print_info "BUILD file for a total of #{gem_count} is #{output_stream.string.size} bytes long."
      print_info 'BUILD file\'s full path is: [' + File.absolute_path(generated_build_file).red + ']'

      # binstubs_build_file.puts %%\n\nexports_files(#{binstubs.keys.to_s})%

      # Write the actual BUILD file
      ::File.open(generated_build_file, 'w') { |f| f.puts output_stream.string }
      ::File.open(generated_binstub_build_file, 'w') { |f| f.puts binstubs_build_file.string }

      # save and run buildifier all at once.
      buildify!(generated_build_file) if run_buildifier?
      buildify!(generated_binstub_build_file) if run_buildifier?

      print_info 'OK — BUILD file for '.green + gem_count.to_s.yellow + ' gems is generated'.green
    end

    private


    # This method scans the contents of the Gemfile.lock and if it finds BUNDLED WITH
    # it strips that line + the line below it, so that any version of bundler would work.
    def remove_bundler_version!
      contents = File.read(gemfile_lock_file)
      unless contents !~ /BUNDLED WITH/
        print_info 'Removing BUNDLED WITH from the Gemfile.lock...'.pink
        temp_lock_file = "#{gemfile_lock_file}.no-bundle-version"
        system %(sed -n '/BUNDLED WITH/q;p' "#{gemfile_lock_file}" > #{temp_lock_file})
        ::FileUtils.rm_f(gemfile_lock_file) if File.symlink?(gemfile_lock_file) # it's just a symlink
        ::FileUtils.move(temp_lock_file, gemfile_lock_file, force: true)
      end
    end

    def attribute_map_global
      @attribute_map_global ||= {
          ruby_version:   ruby_version,
          repo_name:      repo_name,
          bundle_path:    bundle_path,
          workspace_name: workspace_name,
          gem_prefix:     gem_prefix,
          rubyopts:       ["-r${RUNFILES_DIR}/#{repo_name}/#{bundle_path}/lib/bundler/setup.rb"]
      }
    end

    def gem_path(spec)
      "#{gem_prefix}/#{spec.name}-#{spec.version}"
    end

    def attribute_map_for_gem(spec)
      # We want to exclude files and folder with spaces in them
      exclude_array = (excludes[spec.name] || []) + ['**/* *.*', '**/* */*']
      {
          exclude:  exclude_array.to_s,
          name:     spec.name,
          version:  spec.version.to_s,
          deps:     spec_deps(spec).to_s,
          gem_path: package_path(gem_path(spec)),
      }.merge(attribute_map_global)
    end

    def package_path(path)
      "${RUNFILES_DIR}/#{path}"
    end

    def generate_gems_targets(spec)
      print_info "adding gem #{spec.name.to_s.red} v#{spec.version.to_s.green}"

      gems_attrs = attribute_map_for_gem(spec)

      output_stream.puts(
          render_template(
              templates.gem_library,
              gems_attrs
          )
      )

      each_gem_executable(gem_path(spec)) do |gem_executable|
        # save this file for binstubs
        binstubs[gem_executable.file] = spec

        # output_stream.puts(
        #    render_template(
        #        templates.gem_binary,
        #        gems_attrs.merge(label:     gem_executable.label,
        #                         full_path: package_path(gem_executable.full_path),
        #                         deps:      spec_deps(spec).append(":#{spec.name}"))
        #    )
        # )

        binstubs_build_file.puts(
            render_template(
                templates.gem_binary,
                gems_attrs.merge(label:     gem_executable.file,
                                 full_path: gem_executable.file,
                                 deps:      bin_spec_deps(spec))
            )
        )
      end
    end

    # generates a list of dependencies as Bazel labels
    def spec_deps(spec)
      [].tap do |d|
        d << spec.dependencies.map(&:name)
        d << 'bundler_setup'
        d.flatten!
        d
      end.map { |name| ":#{name}" }
    end

    # generates a list of dependencies as Bazel labels
    def bin_spec_deps(spec)
      [].tap do |d|
        d << spec.dependencies.map(&:name)
        d << 'bundler_setup'
        d << spec.name
        d.flatten!
      end.map { |name| "//:#{name}" }
    end

    SKIP_EXECUTABLES = %w(console setup).freeze

    # Finds any executables under the gem path and exposes them
    def each_gem_executable(rel_gem_path)
      return unless block_given?

      %w(exe bin).each do |bin_dir|
        gems_full_path = "#{rel_gem_path}/#{bin_dir}"

        next unless Dir.exist?(gems_full_path)

        Dir.glob("#{rel_gem_path}/#{bin_dir}/**/*").each do |full_path|
          filename = File.basename(full_path)
          next if SKIP_EXECUTABLES.include?(filename)
          next unless File.executable?(full_path)

          yield(GemExecutable.new(rel_gem_path, full_path))
        end
      end
    end

    # Given a template and an attribute hash, replaces keys with values
    def render_template(template, attribute_map)
      attribute_map.inject(template) do |t, (key, value)|
        t.gsub("{#{key}}", value.to_s)
      end
    end

    def run_buildifier?
      buildifier != false
    end

    def binstubs_build_file
      @binstubs_build_file ||= StringIO.new
    end

    def output_stream
      @output_stream ||= StringIO.new
    end

    def templates
      BuildTemplates.templates
    end
  end

  class Buildifier
    include Helpers
    attr_reader :build_file, :output_file

    def initialize(build_file)
      @build_file = build_file

      # For capturing buildifier output
      @output_file = ::Tempfile.new("/tmp/#{File.dirname(File.absolute_path(build_file))}/#{build_file}.stdout").path
    end

    def run!
      raise BuildifierCantRunError, 'Can\'t find the BUILD file' unless File.exist?(build_file)

      # see if we can find buildifier on the filesystem
      buildifier = `bash -c 'command -v buildifier'`.strip

      raise BuildifierCantRunError, 'Can\'t find buildifier' unless buildifier && File.executable?(buildifier)

      command = "#{buildifier} -v #{File.absolute_path(build_file)}"
      system("/usr/bin/env bash -c '#{command} 1>#{output_file} 2>&1'")
      code = $?

      output = File.read(output_file).strip.gsub(Dir.pwd, '.').yellow
      begin
        FileUtils.rm_f(output_file)
      rescue StandardError
        nil
      end

      print_info "buildifier said: #{output}" if output

      if code == 0
        print_info 'Buildifier gave 👍'.green
      else
        raise BuildifierFailedError,
              'Generated BUILD file failed buildifier, with error — '.red + "\n\n" +
                  File.read(output_file).yellow
      end
    end
  end


  class Parser
    USAGE = <<~HELP
      #{'USAGE'.help_header}
        ruby_bundle.rb [options]

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
# ruby ./ruby_bundle.rb
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
    if options.verbose
      puts 'PARSED ARGUMENTS > begin ——————————————'.yellow
      pp options.to_h
      puts 'PARSED ARGUMENTS > end   ——————————————'.yellow
    end

    RulesRuby::Bundle.new(**options.to_h).generate_bazel_build_file!
  rescue StandardError => e
    puts 'ERROR — '.red + e.message.yellow
    if verbose
      puts 'STACKTRACE: '
      puts e.backtrace.join("\n").red
    end
  end
end
