#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'rubygems/name_tuple'
require 'rubygems/package'
require 'rubygems/remote_fetcher'
require 'rubygems/source'
require 'tmpdir'

def unpack_gem(name, version, dest = Dir.pwd)
  source = Gem::Source.new('https://rubygems.org')
  spec = source.fetch_spec Gem::NameTuple.new(name, version)

  Dir.mktmpdir do |dir|
    Dir.chdir(dir) { source.download(spec) }
    downloaded = File.join(dir, "#{name}-#{version}.gem")
    Gem::Package.new(downloaded).extract_files(dest)
  end
end

def main
  gem_name, gem_version, dir, = *ARGV
  dir ||= Dir.pwd
  unless gem_name && gem_version
    puts "USAGE: #{$0} gem-name gem-version destination-folder"
    exit 1
  end
  unpack_gem(gem_name, gem_version, dir)
end

if $0 == __FILE__
  main
end
