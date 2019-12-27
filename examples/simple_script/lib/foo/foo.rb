# frozen_string_literal: true

require 'simple_script'
require 'forwardable'

module SimpleScript
  class Foo
    extend Forwardable

    def_delegators :@output, :puts
    attr_accessor :output
    def initialize(argv = ARGV)
      @output = SimpleScript.output
      return unless argv&.first == 'foo'

      aha!
    end

    def aha!
      puts 'Congratulations! You\'ve accomplished a complete FUBAR!'
    end
  end
end
