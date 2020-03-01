# vim: ft=ruby
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "{gem_name}"
  spec.version       = "{gem_version}"
  spec.summary       = "{gem_summary}"
  spec.description   = "{gem_description}"
  spec.homepage      = "{gem_homepage}"
  
  spec.authors       = {gem_authors}
  spec.email         = {gem_author_emails}

  spec.files         = {gem_sources}
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = {gem_require_paths}

  spec.required_ruby_version = '>= 2.3'

  {gem_runtime_dependencies}
  
  {gem_development_dependencies}
end
