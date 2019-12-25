# frozen_string_literal: true

module RulesRuby
  RUBYGEMS = 'https://rubygems.org'

  class << self
    # for a given ruby version, eg 2.6.5 returns the major/minor
    # version only, i.e. 2.6.0 as does ruby.
    def canonical_version(ruby_version = RUBY_VERSION)
      (ruby_version.split('.')[0..1] << 0).join('.')
    end

    def report_error(msg)
      warn msg
    end
  end

  RUBY_MAJOR_VERSION = canonical_version
end
