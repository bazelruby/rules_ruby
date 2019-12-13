# frozen_string_literal: true

require 'openssl'
require 'lib/foo'
require "awesome_print"

def oss_rand
  OpenSSL::BN.rand(512).to_s
end

puts Foo.aha + " " + oss_rand

puts $LOAD_PATH

ap Class