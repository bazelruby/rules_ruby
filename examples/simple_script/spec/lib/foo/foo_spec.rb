# frozen_string_literal: true
require 'rspec'
require 'rspec/its'
require 'simple_script'
require 'foo/foo'
require 'stringio'

RSpec.describe SimpleScript::Foo do
  let(:argv) { %w(one two three) }
  let(:output) { StringIO.new }

  subject(:foo) { described_class.new(argv) }
  before { foo.output = output }

  context 'customized output stream' do
    subject { output }
    its(:size) { should be_zero }
  end
end

