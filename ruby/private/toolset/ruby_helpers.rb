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

  module Helpers
    class << self
      attr_accessor :prog_name
    end

    self.prog_name = 'helpers'

    def ruby_version(ruby_version = RUBY_VERSION)
      @ruby_version ||= (ruby_version.split('.')[0..1] << 0).join('.')
    end

    # Path where the gem sources can be found
    # eg. "ruby/2.6.0/gems/rubocop-0.78.0"
    def relative_gem_path(gem_tuple)
      @relative_gem_path ||= "ruby/#{ruby_version}/gems/#{gem_tuple.name}-#{gem_tuple.version}"
    end

    def hdr(class_or_instance)
      puts "\n\n"
      puts Helpers.prog_name.light_blue + " ❬ #{class_or_instance.is_a?(Class) ? class_or_instance.name : class_or_instance.class.name} ❭ ".red
    end

    def inf(*args)
      puts Helpers.prog_name.light_blue + ' ❬ ' + args.map(&:to_s).join(' ').to_s + ' ❭ '
    end

    def wrn(*args)
      puts Helpers.prog_name.yellow + ' ❬ ' + args.map(&:to_s).join(' ').to_s.red + ' ❭ '
    end
  end

  class GemInfo < Struct.new(:name, :version, :gem_home, :sources, :use_nested_path)
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
end
