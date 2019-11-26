require_relative '../spec_helper'

require 'apps/foo-bar/lib/foo/version'

describe Foo do
  it { expect(Foo).to be_const_defined(:VERSION) }
end
