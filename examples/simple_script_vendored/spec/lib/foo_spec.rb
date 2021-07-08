# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/foo'

RSpec.describe Foo do
  let(:goo) { 'Green slime was dripping down his throat into his lapdomen...' }
  subject(:foo) { Foo.new(goo) }

  context 'without the aha' do
    before { allow(Foo).to receive(:yell_aha).and_return('tiny dongle') }

    it "should have goo" do
      expect(subject.goo).to eql goo
    end
    it "should have transformed goo" do
      expect(subject.transform).not_to eql goo
    end

    # Some rot13 old school encryption :)
    it "should use rot13 for transform" do
      expect(subject.transform).to eql 'Gerra fyvzr jnf qevccvat qbja uvf guebng vagb uvf yncqbzra...'
    end
  end

  context 'aha' do
    it 'should print aha' do
      expect(Foo).to receive(:puts).with('You said, aha?').and_return(nil)
      Foo.yell_aha
    end
  end
end
