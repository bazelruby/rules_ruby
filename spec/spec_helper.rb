# frozen_string_literal: true

require 'rspec'
require 'rspec/its'

require_relative '../ruby/private/toolset/ruby_helpers'
require_relative '../ruby/private/toolset/ruby_bundle_install.rb'
require_relative '../ruby/private/toolset/ruby_install_gem.rb'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
