# frozen_string_literal: true

require 'spec_helper'

module RulesRuby
  RSpec.describe BuildFileGenerator do
    let(:args) { %w(sym) }
    subject(:bfg) { described_class }

    its(:name) { should eq 'RulesRuby::BuildFileGenerator' }
  end
end
