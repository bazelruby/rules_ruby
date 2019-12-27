# frozen_string_literal: true

require 'simple_script'
require 'rspec'
require 'rspec/its'

describe SimpleScript do
  subject(:simple_module) { described_class }
  let(:output) { StringIO.new }

  before { simple_module.output = output }

  context 'generates a random string' do
    before { expect(output.string).to be_empty }

    its(:oss_rand) { should be nil }
    it 'should now have a random string in the output' do
      expect(output.string.size).to be_zero
      expect(simple_module.oss_rand).to be_nil
      expect(output.string.size).not_to be_zero
    end
  end
end
