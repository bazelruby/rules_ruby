# frozen_string_literal: true

#
# This file effectively implements 'gem install <name> --version=<version>'
#
require 'rubygems'
require 'rubygems/name_tuple'
require 'rubygems/package'
require 'rubygems/remote_fetcher'
require 'rubygems/source'
require 'tmpdir'
require 'singleton'

module RulesRuby
  class << self
    # for a given ruby version, eg 2.6.5 returns the major/minor
    # version only, i.e. 2.6.0 as does ruby.
    def canonical_ruby_version(ruby_version = RUBY_VERSION)
      (ruby_version.split('.')[0..1] << 0).join('.')
    end
  end

  # This singleton class encapsulates the RubyGems sources
  class GemSource
    RUBYGEMS = 'https://rubygems.org'
    include Singleton
    class << self
      def spec(*args, &block)
        instance.spec(*args, &block)
      end
    end

    def spec(gem_name, gem_version)
      gem_source.fetch_spec Gem::NameTuple.new(gem_name, gem_version)
    end

    def gem_source
      @gem_source ||= Gem::Source.new(RUBYGEMS)
    end
  end

  # This Class encapsulates a single gem version and provides
  # methods to download and unpack it into a folder, to
  class GemHandler
    attr_reader :gem_name, :gem_version, :gem_home,
                :ruby_version

    def initialize(gem_name, gem_version, gem_home = Dir.pwd, ruby_version = RUBY_VERSION)
      @gem_name = gem_name
      @gem_version = gem_version
      @gem_home = gem_home
      @ruby_version = ruby_version
    end

    # Actions
    def unpack!
      spec = GemSource.spec(gem_name, gem_version)
      Dir.mktmpdir { |dir|
        Dir.chdir(dir) { GemSource.instance.gem_source.download(spec) }
        downloaded = File.join(dir, "#{gem_name}-#{gem_version}.gem")
        Gem::Package.new(downloaded).extract_files(gem_home)
      }
    end

    # Public Properties
    # Path where the gem sources can be found
    # eg. "lib/ruby/2.6.0/gems/rubocop-0.78.0"
    def gem_path
      @gem_path ||= "lib/ruby/#{::RulesRuby.canonical_ruby_version}/gems/#{gem_name}-#{gem_version}"
    end

    # An array of executuables provided with the gem, with binpath prepended.
    # eg. [ "bin/rubocop" ]
    def executables
      @executables ||= gemspec&.executables&.map { |e| "#{bindir}/#{e}" }
    end

    def gemspec
      return @gemspec if @gemspec&.is_a?(Gem::Specification)

      if Dir.exist?(gem_path) && File.exist?("#{gem_path}/#{gem_name}.gemspec")
        Gem::Specification.load("#{gem_path}/#{gem_name}.gemspec")
      end.tap do |spec|
        pp spec
      end
    rescue StandardError => e
      puts "DEBUG: no gemspec found at #{gem_path} for #{gem_name}: #{e.inspect}"
    end

    # List of require paths that should be added to the LOAD_PATH
    # eg [ "lib", "app" ]
    def require_paths
      gemspec&.require_paths
    end

    def name
      gemspec&.name
    end

    def sources
      gemspec.files
    end

    private

    def bindir
      gemspec&.bindir
    end
  end
end

if $0 == __FILE__
  ::RulesRuby::GemHandler.new(*ARGV).unpack!
end
