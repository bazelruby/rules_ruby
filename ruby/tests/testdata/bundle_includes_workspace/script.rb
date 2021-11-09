expected_gem_require_paths = %w[
  etc
  src/ruby/bin
  src/ruby/lib
  src/ruby/pb
]
gem_require_paths = $LOAD_PATH.map do |load_path|
  %r{.+script.runfiles/(?:gems|bundle)/lib/ruby/3.0.0/gems/grpc-.+?/(.+)}.match(load_path).to_a[1]
end.compact

begin
  require 'grpc'
rescue LoadError => e
  warn "Failed to load grpc gem: #{e.message}"
  raise
end

pp GRPC::RpcServer.new

# TODO: what is this?  I am not sure I fully understand the purpose of this
# check. Please elaborate, or it will be removed. --@kigster
(expected_gem_require_paths - gem_require_paths).each do |missing_require_path|
  raise "Expected requir_path '#{missing_require_path}' is missing in $LOAD_PATH."
end
