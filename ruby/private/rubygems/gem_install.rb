# frozen_string_literal: true

#
# This file effectively implements 'gem install <name> --version=<version>'
#
require 'rubygems'
require 'rubygems/name_tuple'
require 'rubygems/source_list'
require 'rubygems/package'
require 'rubygems/remote_fetcher'
require 'rubygems/source'
require 'tmpdir'
require 'singleton'
require 'forwardable'

require_relative 'rules_ruby'

module RulesRuby
  class GemInstall
    extend Forwardable

    def_delegators :@gemspec, :require_paths, :bindir
    def_delegators :@gem_tuple, :name, :version

    attr_reader :gem_tuple,
                :gem_home,
                :major_ruby_version,
                :rubygems_sources,
                :debug

    def initialize(name:,
                   version:,
                   gem_home: Dir.pwd,
                   debug: false,
                   rubygems_sources: [::RulesRuby::RUBYGEMS],
                   major_ruby_version: RUBY_VERSION)

      raise ArgumentError, 'Gem name and version are required' unless name && version

      @gem_tuple = ::Gem::NameTuple.new(name, version)
      @debug     = debug
      @gem_home  = gem_home

      FileUtils.mkdir_p(gem_home) unless Dir.exist?(gem_home)

      @major_ruby_version = ::RulesRuby.canonical_version(major_ruby_version)
      @rubygems_sources   = ::Gem::SourceList.from(rubygems_sources)
    end

    # Public actions
    #
    def download_and_extract!
      return true if gem_downloaded?

      spec = remote_source_spec(sources: rubygems_sources, tuple: gem_tuple)
      gem_not_found_error if spec.nil?

      Dir.mktmpdir do |dir|
        Dir.chdir(dir) { spec.download! }
        downloaded = File.join(dir, "#{name}-#{version}.gem")
        # expand the archive into gem_path
        ::Gem::Package.new(downloaded).extract_files(gem_path)
        gemspec
      end

      gem_downloaded?
    end

    def gemspec_file
      @gemspec_file ||= "#{gem_path}/#{name}.gemspec"
    end

    # Iterates over multiple Gem::Source instances and returns
    # the first spec that matches. Order rubygem sources with the
    # larger source first to speed up this process.
    def remote_source_spec(sources: rubygems_sources, tuple: gem_tuple)
      return @remote_source_spec if @remote_source_spec

      sources.sources.each do |source|
        spec = source.fetch_spec(tuple)
        if spec
          @remote_source_spec = GemSourceSpec.new(spec, source)
          break
        end
      rescue Gem::RemoteFetcher::FetchError => e
        warn "ERROR fetching #{gem_tuple}: #{e.message}"
        nil
      end
      @remote_source_spec
    end

    def fetch_gemspec(**opts)
      @fetch_gemspec ||= remote_source_spec(**opts)&.spec
    end

    # Returns a Gem::Specification instance by either reading a local
    # gemspec file (if exists) or fetching it from the remote source.
    def gemspec
      return @gemspec if @gemspec&.is_a?(::Gem::Specification)

      @gemspec = if File.exist?(gemspec_file)
                   ::Gem::Specification.load(gemspec_file)
                 end
    end

    # Path where the gem sources can be found
    # eg. "lib/ruby/2.6.0/gems/rubocop-0.78.0"
    def relative_gem_path
      @relative_gem_path ||= "lib/ruby/#{major_ruby_version}/gems/#{name}-#{version}"
    end

    # combines provided gem_home and relative path. If gem_home is relative, the result
    # is also relative.
    def gem_path
      @gem_path ||= "#{gem_home}/#{relative_gem_path}"
    end

    # An array of executuables provided with the gem, with binpath prepended.
    # eg. [ "bin/rubocop" ]
    def executables
      return @executables if @executables

      [].tap do |executables|
        %w(exe bin).each do |bin_dir|
          next unless Dir.exist?("#{gem_path}/#{bin_dir}")

          Dir.glob("#{gem_path}/#{bin_dir}/*").each do |executable|
            executables << executable if File.executable?(executable)
          end
        end

        @executables = executables unless executables.empty?
      end
    end

    private

    def gem_downloaded?
      debug_puts "Gem #{gem_tuple} downloaded, spec at #{gemspec_file}" if debug && File.exist?(gemspec_file)
      File.exist?(gemspec_file)
    end

    def gem_not_found_error(msg = 'Gem was not found in the remote or local sources')
      raise GemNotFoundError.new(gem_tuple: gem_tuple,
                                 sources: rubygems_sources,
                                 error: msg.yellow)
    end

    def debug_puts(msg)
      $stdout.puts ">>> #{msg} " if @debug
    end

    def debug_pp(obj)
      pp obj if @debug
    end
  end

  # Exception thrown when none of the Gem source contain our gem.
  class GemNotFoundError < Gem::LoadError
    attr_reader :sources, :error

    def initialize(gem_tuple:, sources: [], error: nil)
      @name        = gem_tuple.name
      @requirement = gem_tuple.version
      @sources     = sources.map(&:to_s)
      @error       = error
    end

    def message
      @message ||= "Gem fetch error for #{name} (#{requirement}): " \
                   "#{@error.is_a?(Exception) ? @error.message : @error}, " \
                   "checked in sources: #{sources}"
    end
  end

  # This Class encapsulates a single gem version and provides
  # methods to download and unpack it into a folder, to
  GemSourceSpec = Struct.new(:spec, :source) do
    def download!
      source.download(spec) if spec && source
    end
  end
end

if $0 == __FILE__
  opts = { name: ARGV[0],
           version: ARGV[1],
           debug: ARGV[2],
           gem_home: (ARGV[3] || './GEM_HOME') }
  ::RulesRuby::GemInstall.new(**opts).unpack!
end
