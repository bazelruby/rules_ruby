# frozen_string_literal: true

require 'spec_helper'
require 'script'

describe 'oss_rand' do
  it 'generates a String' do
    expect(oss_rand).to be_a_kind_of String
  end
end
