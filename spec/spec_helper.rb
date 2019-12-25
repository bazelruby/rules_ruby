# frozen_string_literal: true

require 'rspec'
require 'rspec/its'

require_relative '../ruby/private/rubygems/rules_ruby'
require_relative '../ruby/private/rubygems/gem_install'
require_relative '../ruby/private/rubygems/bundle_install'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
