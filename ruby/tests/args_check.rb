# frozen_string_literal: true

# Checks if args to ruby_binary rules propagate to the actual
# ruby processes

expected = %w[foo bar baz]

unless ARGV == expected
  raise "Expected ARGV to be #{expected}; got #{ARGV}"
end
