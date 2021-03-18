# frozen_string_literal: true

class Foo
  class << self
    def yell_aha
      puts aha
    end

    def aha
      'You said, aha?'
    end

    def rot13(value)
      return nil unless value.is_a?(String)

      value.tr('abcdefghijklmnopqrstuvwxyz', 'nopqrstuvwxyzabcdefghijklm')
    end
  end

  attr_reader :goo, :foo

  def initialize(goo)
    @goo = goo
    @foo = transform(goo)
  end

  def transform(incoming = goo)
    Foo.rot13(incoming)
  end
end
