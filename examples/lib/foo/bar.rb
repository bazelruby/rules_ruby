# frozen_string_literal: true

require 'openssl'

module Foo
  class Bar
    def initialize
      @key = OpenSSL::BN.rand(512)
    end
  end
end
