# frozen_string_literal: true

#
# © 2018-2020 BazelRuby Authors
#
# This ruby helper installs Bundler when called without arguments.
# Alternatively, it can be called to install ANY gem like so:
# ———————————————————————————————————————————————————————————————————————————————————
#
# Example:
#    ./install_gem.rb -n nokogiri:1.8.7.1 -g ~/.gems -p
#
#
# ❯ ruby ruby_install_gem.rb -h
# USAGE:
#    ruby_install_gem.rb [gem[:version]] [ options ]
#
# DESCRIPTION
#    Downloads and Install a gem in the repository or in the Bazel's build folder,
#    Used by bundle_install.rb to install bundler itself.
#
# EXAMPLE:
#    # This will install to ./vendor/bundle/rspec-3.2.0
#    ruby_install_gem.rb rspec:3.2.0 -g vendor/bundle -s https://rubygems.org
#
#    # This will install to ~/.gems/ruby/2.5.0/gems/sym-2.8.1
#    ruby_install_gem.rb -n sym -v 2.8.1 -g ~/.gems -p
#
# OPTIONS:
#
#    -n, --gem-name=NAME[:VERSION]    Name of the gem to install. May include the
#                                     version after the ":".
#    -v, --gem-version=N.Y.X          Gem version to install, optional.
#    -s, --sources URL1,URL2..        Optional list of URIs to look for gems at
#    -g, --gem-home=PATH              Directory where the gem should be installed.
#    -p, --nested-path                If set, the gem will be installed under the
#                                     gem-path provided, but in a deeply nested folder
#                                     corresponding to a ruby standard.
#
#                                     For instance, if GEM_HOME is "./vendor/bundle",
#                                     and -p is set, then the resulting gem folder will
#                                     be the following path (for rspec-core):
#                                     ./vendor/bundle/ruby/2.5.0/gems/rspec-core-3.9.0
#                                     assuming Ruby 2.5.* version.
#    -h, --help                       Prints this help
#
# ———————————————————————————————————————————————————————————————————————————————————

# install any gem whatsoever.

require 'rubygems'
require 'rubygems/name_tuple'
require 'rubygems/package'
require 'rubygems/remote_fetcher'
require 'rubygems/source'
require 'tmpdir'
require 'forwardable'
require 'optparse'
require 'ostruct'

require_relative 'ruby_helpers'

DEFAULT_BUNDLER_VERSION  = '2.1.2'
DEFAULT_BUNDLER_GEM_HOME = 'vendor/bundle'

DEBUG = ENV['DEBUG']

module RulesRuby
  class GemInstall
    extend Forwardable

    def_delegators :@gem_info, :name, :version, :gem_home, :sources, :user_nested_path

    attr_reader :spec, :errors, :result, :sources, :name_tuple

    include ::RulesRuby::Helpers
    Helpers.prog_name = 'ruby-install-gem'

    def initialize(gem_info)
      @gem_info   = gem_info
      @name_tuple = Gem::NameTuple.new(name, version)
      @sources    = gem_info.sources.map { |uri| Gem::Source.new(uri) }
      @source     = source # fetch from sources

      if @source.nil?
        raise GemfileNotFound, "Gem #{gem_info} was not found in #{sources}"
      end

      @spec   = source&.fetch_spec(Gem::NameTuple.new(name, version))
      @result = nil
      @errors = []
    end

    # Unpacks the gem contents into a given library.
    def install!
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { source.download(spec) }
        gem_spec = "#{name}-#{version}.gem"
        downloaded = File.join(dir, gem_spec)
        Gem::Package.new(downloaded).extract_files(gem_home)
        inf "OK : ".green + "extracted #{gem_spec.red} to #{gem_home.blue}"
        inf "PWD: " + File.absolute_path(gem_home).red
      end
      @result = true
      exit(0)
    rescue StandardError => e
      warn "Exception while attempting to unpack gem #{name} (#{version}) to #{gem_path}: ".red
      warn " • #{e.message}"
      @result = false
      @errors << e.message
      STDERR.pp @errors
      exit(0)
    end

    private

    # Cache the result of remote_source_spec
    def source
      @source ||= remote_source_for_spec
    end

    # If multiple RubyGem sources are provided, check for this gem
    # until one of them has it, or bail if none do.
    def remote_source_for_spec
      sources.each do |source|
        gem_spec = source.fetch_spec(name_tuple)
        return source if gem_spec
      rescue Gem::RemoteFetcher::FetchError
        nil
      end
    end
  end

  class CLI
    extend Forwardable
    def_delegators :@gem_info, :name, :version, :gem_home, :sources, :use_nested_path

    attr_accessor :options, :gem_info

    include ::RulesRuby::Helpers
    Helpers.prog_name = 'ruby-install-gem-cli'

    def initialize(cli_options)
      @options  = cli_options
      @gem_info = cli_options.tuple

      installer = GemInstall.new(gem_info).install!

      if installer.result
        inf 'OK  : ', gem_info.to_s
        inf 'ROOT: ', Dir.pwd.to_s.pink
      else
        wrn "Error installing #{self}:\n#{@errors.join(', ')}".red
        exit(1)
      end
    end

    class << self
      def transform_options(options)
        options.tuple = RulesRuby::GemInfo.new(options.gem_name,
                                               options.gem_version,
                                               options.gem_home,
                                               options.sources,
                                               options.use_nested_path)
        options.tuple.valid? ? options.tuple : show_help
      end

      def show_help
        puts 'Invalid arguments provided, please ensure correct flags.'.red
        puts
        parse_argv(Array('-h'))
      end

      def parse_argv(argv = ARGV.dup)
        OpenStruct.new.tap do |options|
          # Accept first argument as the gem:version in addition to flags.
          options.gem_name, options.gem_versions = argv.first.split(':') \
            if !argv.first.nil? && !argv.first.start_with?('-')

          options.gem_name        = nil
          options.gem_version     = nil
          options.sources         = %w(https://rubygems.org)
          options.gem_home        = ENV['GEM_HOME'] || '.'
          options.use_nested_path = false

          opt_parser = OptionParser.new do |opts|
            opts.banner = USAGE + "\n" + EXAMPLES
            opts.separator ''
            opts.on('-n', '--gem-name=NAME[:VERSION]',
                    'Name of the gem to install. May include the',
                    'version after the ":".') do |n|
              if n.include?(':')
                options.gem_name, options.gem_version = n.split(':')
              else
                options.gem_name = n
              end
            end

            opts.on('-v', '--gem-version=N.Y.X',
                    'Gem version to install, optional.') do |n|
              options.gem_version ||= n
            end

            opts.on('-s', '--sources URL1,URL2..',
                    'Optional list of URIs to look for gems at') do |n|
              options.sources = n.split(',').map { |u| URI(u) }
            end

            opts.on('-g', '--gem-home=PATH',
                    'Directory where the gem should be installed.') do |n|
              options.gem_home = n
            end

            opts.on('-p', '--nested-path',
                    'If set, the gem will be installed under the gem-path provided,',
                    'but in a deeply nested folder corresponding to a ruby standard.',
                    ' ',
                    'For instance, if GEM_HOME is "./vendor/bundle", and -p is set, then ',
                    'the resulting gem folder will be the following path (for rspec-core):',
                    './vendor/bundle/ruby/2.5.0/gems/rspec-core-3.9.0'.yellow,
                    'assuming Ruby 2.5.* version.') do |*|
              options.use_nested_path = true
            end

            opts.on('-h', '--help', 'Prints this help') do
              puts opts
              exit
            end

            opts.separator ''
          end

          opt_parser.parse!(argv)
        end
      end
    end

    USAGE = <<~INFO
      #{'USAGE'.pink}:
          #{File.basename($0).on_orange + ' [gem[:version]] [ options ]'.on_orange}

      #{'DESCRIPTION'.pink}
          Downloads and Install a gem in the repository or in the Bazel's
          build folder, Used by bundle_install.rb to install bundler itself.
    INFO

    EXAMPLES = <<~EX
      #{'EXAMPLE'.pink}:
          # This will install to ./vendor/bundle/rspec-3.2.0
          #{File.basename($0)} rspec:3.2.0 -g vendor/bundle -s https://rubygems.org

          # This will install to ~/.gems/ruby/2.5.0/gems/sym-2.8.1
          #{File.basename($0)} -n sym -v 2.8.1 -g ~/.gems -p

      #{'OPTIONS'.pink}:
    EX
  end
end

if $0 == __FILE__
  module RulesRuby
    CLI.class_eval do
      ::RulesRuby::GemInstall.new(transform_options(parse_argv(ARGV))).install!
    end
  end
end
