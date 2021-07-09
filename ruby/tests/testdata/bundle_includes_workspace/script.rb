# frozen_string_literal: true

expected_gem_require_paths = [
  'etc',
  'src/ruby/bin',
  'src/ruby/lib',
  'src/ruby/pb'
]

gem_require_paths = $LOAD_PATH.map do |load_path|
  %r{.+script.runfiles/(?:gems|bundle)/lib/ruby/3.0.0/gems/grpc-.+?/(.+)}.match(load_path).to_a[1]
end.compact

(expected_gem_require_paths - gem_require_paths).each do |missing_require_path|
  raise "Expected requir_path '#{missing_require_path}' is missing in $LOAD_PATH."
end

begin
  require 'grpc'
rescue LoadError
  $stderr.puts 'Failed to load grpc gem'
  raise
end

puts GRPC::RpcServer.new
