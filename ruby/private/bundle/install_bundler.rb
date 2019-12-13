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

  Dir.mktmpdir { |dir|
    Dir.chdir(dir) { source.download(spec) }
    downloaded = File.join(dir, "#{name}-#{version}.gem")
    Gem::Package.new(downloaded).extract_files dest
  }
end

def main
  version = ARGV[0]
  dir = ARGV[1] || Dir.pwd
  unpack_gem('bundler', version, dir)
end

if $0 == __FILE__
  main
end
