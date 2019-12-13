# frozen_string_literal: true

puts $LOAD_PATH

require 'openssl'
require 'lib/foo'
require "awesome_print"

def oss_rand
  OpenSSL::BN.rand(512).to_s
end

puts Foo.aha + " " + oss_rand

ap Class