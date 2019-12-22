# frozen_string_literal: true

#
# ruby ./install_build_file.rb "BUILD.bazel" "Gemfile.lock" "repo_name" "[]" "wsp_name"
#
require "bundler"
require 'json'
require 'stringio'
require 'erb'

require_relative '../rubygems/gem_handler'

module RulesRuby
  ERB_FILE = ::File.expand_path('../BUILD.gem.erb', __FILE__)
  GEM_TEMPLATE = ERB.new(::File.read(ERB_FILE))

  class << self
    def bundler_build_template
      @bundler_build_template ||= ::ERB.new(::DATA.read).freeze
    end
  end

  class BuildFileGenerator
    attr_reader :build_out_file,
                :gemfile_lock,
                :repo_name,
                :excludes,
                :workspace_name

    def initialize(build_out_file,
                   gemfile_lock,
                   repo_name,
                   excludes,
                   workspace_name)

      @build_out_file = build_out_file
      @gemfile_lock = gemfile_lock
      @repo_name = repo_name
      @excludes = excludes
      @workspace_name = workspace_name
    end

    def generate!
      ruby_version = RulesRuby.canonical_ruby_version(RUBY_VERSION)

      template_out = StringIO.new
      template_out.puts ::RulesRuby.bundler_build_template.result(binding)

      # Append to the end specific gem libraries and dependencies
      bundle = Bundler::LockfileParser.new(Bundler.read_file(gemfile_lock))

      bundle.specs.each do |spec|
        puts "Processing gem #{spec.name} version #{spec.version}"

        deps = spec.dependencies.map(&:name)

        # Now define what the tempalte will use
        deps += [":bundler_setup"]

        gem = ::RulesRuby::GemHandler.new(
          spec.name,
          spec.version,
          Dir.pwd,
          ruby_version
        ).tap(&:unpack!)

        exclude_array = excludes[spec.name] || []
        # We want to exclude files and folder with spaces in them
        exclude_array += ["**/* *.*", "**/* */*"]

        template_out.puts GEM_TEMPLATE.result(binding)
      end

      # Write the actual BUILD file
      ::File.open(build_out_file, 'w') { |f|
        f.puts template_out.string
      }
    end
  end
end

if $0 == __FILE__
  if ARGV.size != 5
    puts "! Expecting five arguments:\n\n\toutput file\n\tgemfile_lock\n\trepo_name\n\texcludes\n\tworkspace_name\n"
    exit 1
  end

  ::RulesRuby::BuildFileGenerator.new(*ARGV).generate!
end

__END__

# This is the ERB template of the Bundler's BUILD file.
load(
  "<%= workspace_name %>//ruby:defs.bzl",
  "ruby_library",
)

package(default_visibility = ["//visibility:public"])

filegroup(
  name = "binstubs",
  srcs = glob(["bin/**/*"]),
  data = [":libs"],
)

ruby_library(
  name = "bundler_setup",
  srcs = ["lib/bundler/setup.rb"],
  visibility = ["//visibility:private"],
)

ruby_library(
  name = "bundler",
  srcs = glob(
    include = [
      "bundler/**/*",
    ],
  ),
  rubyopt = ["-r${RUNFILES_DIR}/<%= repo_name %>/lib/bundler/setup.rb"],
)

# PULL EACH GEM INDIVIDUALLY
