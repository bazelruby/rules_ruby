# frozen_string_literal: true

require 'openssl'
require 'awesome_print'

require_relative 'lib/foo'

def oss_rand
  OpenSSL::BN.rand(512).to_s
end

puts Foo.aha + ' ' + oss_rand
