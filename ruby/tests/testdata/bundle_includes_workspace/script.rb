# frozen_string_literal: true

expected_gem_require_paths = [
  'lib',
  'lib/google/*',
  'lib/google/3.0/*',
  'lib/google/protobuf/**/*'
]

gem_require_paths = $LOAD_PATH.map do |load_path|
  %r{.+script.runfiles/(?:gems|bundle)/lib/ruby/3.0.0/gems/google-protobuf-.+?/(.+)}.match(load_path).to_a[1]
end

(expected_gem_require_paths - gem_require_paths).each do |missing_require_path|
  raise "Expected requir_path '#{missing_require_path}' is missing in $LOAD_PATH."
end

begin
  require 'google/protobuf'
rescue LoadError
  $stderr.puts 'Failed to load google-protobuf gem'
  raise
end

puts Google::Protobuf::DescriptorPool.new
