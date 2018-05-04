require_relative '../spec_helper'
require 'foo/version'

describe Foo do
  it { expect(Foo).to be_const_defined(:VERSION) }
end
