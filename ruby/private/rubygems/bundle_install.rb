# frozen_string_literal: true

#
# Usage:
#
# bundle_install "BUILD.bazel" "Gemfile.lock" "repo_name" "[]" "wsp_name"
#
require 'bundler'
require 'json'
require 'stringio'
require 'erb'
require 'optparse'

require_relative 'rules_ruby'
require_relative 'gem_install'

module RulesRuby
  # bundler's build file
  ERB_BDL_BUILD_FILE = ERB.new(File.read(File.expand_path('../BUILD.bundle.erb', __FILE__)))
  # every other gem's build file
  ERB_GEM_BUILD_FILE = ERB.new(File.read(File.expand_path('../BUILD.gem.erb', __FILE__)))

  ATTRS = %i(gemfile_lock_file workspace_name repo_name excludes output_file).freeze

  class BundleInstall
    attr_reader :attrs
    extend Forwardable

    def_delegators :@attrs, *ATTRS

    def initialize(attrs)
      raise ArgumentError, "Invalid constructor attributes: #{attrs.error_message}" unless attrs.valid?

      @attrs = attrs
    end

    def generate!
      # remove BUNDLED WITH from Gemfile.lock
      remove_bundler_version!

      # Generate Bundler's Build File
      output.puts bundler_build_file

      # And now, read Gemfile.lock and for each gem,
      # append to the end specific gem libraries and dependencies
      output.puts bundle.specs.map(&method(:build_rules_for_gem)).join("\n\n")

      # Finally write out the actual BUILD file
      create_build_file!
    end

    def output
      @output ||= StringIO.new
    end

    def ruby_major_version
      @ruby_major_version ||= RulesRuby.canonical_version(RUBY_VERSION)
    end

    def bundler_build_file
      ::RulesRuby::ERB_BDL_BUILD_FILE.result(binding)
    end

    private

    def remove_bundler_version!
      contents = File.read(gemfile_lock_file)
      if contents =~ /BUNDLED WITH/
        tempfile = Tempfile.new("/tmp/gemfile-#{workspace_name}.#{Process.pid}").path
        FileUtils.cp(gemfile_lock_file, "#{gemfile_lock_file}.backup")
        system %(sed -n '/BUNDLED WITH/q;p' "#{gemfile_lock_file}.backup" > #{gemfile_lock_file})
      end
    end

    def bundle
      @bundle ||= Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock_file))
    end

    def create_build_file!
      ::File.open(output_file, 'w') { |f|
        f.puts output.string
      }
    end

    def build_rules_for_gem(spec)
      puts "Downloading and unpacking gem #{spec.name.to_s.green} version #{spec.version.to_s.green}"

      deps = spec.dependencies.map(&:name)

      # Now define what the tempalte will use
      deps += [':bundler_setup']

      gem_home = Dir.pwd

      gem = ::RulesRuby::GemInstall.new(
        name: spec.name,
        version: spec.version,
        gem_home: gem_home,
        debug: ENV['DEBUG']
      ).tap(&:download_and_extract!)

      exclude_array = excludes[spec.name.to_s] || excludes[spec.name.to_sym] || []
      # We want to exclude files and folder with spaces in them
      exclude_array += ['**/* *.*', '**/* */*']

      "\n# #{'—' * 20} #{spec.name} (#{spec.version}) #{'—' * 20} \n\n\n" +
        ::RulesRuby::ERB_GEM_BUILD_FILE.result(binding)
    end
  end

  class << self
    def from_argv(argv = ARGV.dup)
      args = Attributes.parse(argv)
      BundleInstall.new(args)
    end
  end

  class Attributes < Struct.new(*ATTRS)
    def errors(description = nil)
      @errors ||= []
      @errors << description if description
      @errors
    end

    def valid?
      each_pair do |field, value|
        errors("#{field} is required") unless value
      end
      errors.empty?
    end

    def error_message
      errors.join("\n\t • ")
    end

    class << self
      def parse_argv(argv = ARGV.dup)
        new.tap do |args|
          args.excludes          = {}
          args.gemfile_lock_file = 'Gemfile.lock'
          args.output_file       = 'BUILD.bazel'

          opt_parser = OptionParser.new do |opts|
            opts.banner = 'Usage: bundle_install [options]'

            opts.on('-l', '--gemfile-lock=FILE', 'Path to the Gemfile.lock') do |n|
              args.gemfile_lock_file = n
            end

            opts.on('-o', '--output=FILE', 'Bazel Build output file') do |n|
              args.output_file = n
            end

            opts.on('-r', '--repo=NAME', 'Name of the repository') do |n|
              args.repo_name = n
            end

            opts.on('-e', '--excludes=EXCLUDES', 'Comma-separated list of exclude patterns',
                    'Patterns should look like this: "gem1:exclude1:exclude2;gem2:exclude1,exclude2"') do |n|
              n.split(';').each do |gem_string|
                gem_name, *excludes = gem_string.split(':')
                args.excludes[gem_name] = excludes
              end
            end

            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              exit
            end
          end

          opt_parser.parse!(argv)
        end
      end
    end
  end
end

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

  def light_blue
    colorize(36)
  end
end

if $0 == __FILE__
  ::RulesRuby::BundleInstall.from_argv.generate!
end

__END__
