# frozen_string_literal: true

require 'openssl'
require 'awesome_print'

module SimpleScript
  class << self
    attr_accessor :output
  end

  self.output = STDOUT

  def self.oss_rand
    SimpleScript.output.puts "OpenSSL Random Number is: #{OpenSSL::BN.rand(512).to_s}"
  end
end
