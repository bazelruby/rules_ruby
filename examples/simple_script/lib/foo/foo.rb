# frozen_string_literal: true

module SimpleScript
  class Foo
    attr_accessor :output

    def initialize(argv = ARGV)
      self.output = STDOUT

      if argv&.first == 'foo'
        aha!
      end
    end

    def aha!
      output.puts 'Congratulations! You\'ve accomplished a complete FUBAR!'
    end
  end
end
