# frozen_string_literal: true

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def on_orange
    colorize(32)
  end

  def light_blue
    colorize(36)
  end

  def help_header
    "#{upcase}:".on_orange
  end
end

module RulesRuby
  DEFAULT_RUBYGEMS_SOURCE = 'https://rubygems.org'
  BUNDLE_PATH             = 'vendor/bundle'
  DEFAULT_GEMFILE_LOCK    = 'Gemfile.lock'
  DEFAULT_BUILD_FILE      = 'BUILD.bazel'

  # @formatter:off
  class BundleError < StandardError; end
  class GemfileNotFound < BundleError; end
  class BuildifierCantRunError < BundleError; end
  class BuildifierFailedError < BundleError; end
  # @formatter:on


  # Various Shared Helpers
  module Helpers
    class << self
      def included(base)
        base.include(Output)
        base.include(BuildifierHelpers)
        base.instance_eval do
          class << self
            def component(value = nil)
              @tool_name = value if value
              @tool_name
            end
          end
        end
      end
    end

    module Output
      def print_header(class_or_instance = self)
        puts "\n———————————————————————————————————————————————————————————————————".green
        puts component_name + " ❬ #{class_or_instance.is_a?(Class) ? class_or_instance.name : class_or_instance.class.name} ❭ ".red
      end

      def print_info(*args)
        puts component_name + ' ❬ ' + args.map(&:to_s).join(' ').to_s + ' ❭ '
      end

      def print_warning(*args)
        puts component_name + ' ❬ ' + args.map(&:to_s).join(' ').to_s.red + ' ❭ '
      end

      def component_name
        (self.class.component || 'rubygems-installer').yellow
      end
    end


    module BuildifierHelpers
      def buildify!(build_file)
        # Once it's saved, let's run buildifier on it, because why not.
        Buildifier.new(build_file).run!
      rescue BuildifierFailedError => e
        print_warning("ERROR: buildifier error — BUILD file is invalid: #{e.message.yellow}")
        raise
      rescue BuildifierCantRunError => e
        print_warning("WARNING: couldn't run buildifier: #{e.message.yellow}")
      end

      def ruby_version(ruby_version = RUBY_VERSION)
        @ruby_version ||= (ruby_version.split('.')[0..1] << 0).join('.')
      end

      # Path where the gem sources can be found — eg. "ruby/2.6.0/gems/rubocop-0.78.0"
      def relative_gem_path(gem_tuple)
        @relative_gem_path ||= "ruby/#{ruby_version}/gems/#{gem_tuple.name}-#{gem_tuple.version}"
      end
    end
  end


  class Buildifier
    include Helpers
    attr_reader :build_file, :output_file
    component 'ruby-build-buildifier'

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

      if code == 0
        print_info 'Buildifier gave 👍 '.green + (output ? " and said: #{output}" : '')
      else
        raise BuildifierFailedError,
              'Generated BUILD file failed buildifier, with error — '.red + "\n\n" +
                  File.read(output_file).yellow
      end
    end
  end

  class GemInfo < Struct.new(:name,
                             :version,
                             :gem_home,
                             :sources,
                             :use_nested_path)
    include Helpers

    def initialize(*args)
      super(*args)
      self.sources = Array(DEFAULT_RUBYGEMS_SOURCE) unless sources.is_a?(Array)
    end

    def absolute_path
      @absolute_path ||= File.absolute_path(gem_home + '/' + relative_gem_path(name))
    end

    def to_s
      "#{name.blue} (#{version.green}) ➔ [#{gem_home.pink}#{use_nested_path ? '/' + relative_gem_path(self) : ''}]\n"
    end

    def valid?
      name && version && gem_home && sources&.first
    end
  end


  # @gem_spec is the spec generated from the Gemfile.lock.
  # @gem_path is the relative path to the gem's top level folder (one that contains lib)
  # @full_path is the full path to the discovered binary. It's a superset of @gem_path
  class GemExecutable < Struct.new(:gem_path, :full_path)
    # Label is generated for the build files. Eg, rspec-exe
    def label
      @label ||= "#{file}.bin"
    end

    def short_path
      @short_path ||= full_path.sub(gem_path, '')[1..-1]
    end

    def file
      @file ||= File.basename(full_path)
    end
  end


  class BuildTemplates < Struct.new(:bundler, :gem_library, :gem_binary, :header)
    def valid?
      [bundler, gem_library, gem_binary, header].all? { |t| t.length > 100 }
    end

    class << self
      attr_reader :templates

      def load_templates!
        return @templates if @templates&.valid?

        @templates ||= new

        templates.header      = File.read(File.expand_path('../BUILD.header.tpl', __FILE__))
        templates.bundler     = File.read(File.expand_path('../BUILD.bundler.tpl', __FILE__))
        templates.gem_library = File.read(File.expand_path('../BUILD.gem.library.tpl', __FILE__))
        templates.gem_binary  = File.read(File.expand_path('../BUILD.gem.binary.tpl', __FILE__))

        raise ArgumentError, 'Unable to parse BUILD file templates as DATA' unless templates.valid?
      end
    end
  end

  BuildTemplates.load_templates!
end
