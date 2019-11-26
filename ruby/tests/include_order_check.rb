# frozen_string_literal: true

# Checks if require paths set by depender libraries appear earlier than
# the ones by dependees.
# i.e. -I options must be topologically sorted by library dependency as
# Bundler does for gems.

require 'ruby/tests/testdata/a'
require 'ruby/tests/testdata/b'
require 'ruby/tests/testdata/c'
require 'ruby/tests/testdata/f'

DEPS = [
  # siblings
  %w[a b],
  %w[b c],
  %w[c f],

  # parent-child pairs
  %w[a d],
  %w[b d],
  %w[c e],
  %w[d e],
].freeze

actual = $LOAD_PATH.grep(%r[/somewhere/.$]).map { |path|
  path.chars.last
}

unless actual.sort == %w[a b c d e f]
  raise "Expect $LOAD_PATH includes somewhere/{a,b,c,d,e} but it did not"
end

DEPS.each do |earlier, later|
  i = actual.index(earlier)
  j = actual.index(later)

  next if i < j

  raise "Expect #{earlier} precedes #{later} in #{actual} but did not"
end
