#!/usr/bin/ruby
# frozen_string_literal: true

require 'foo'

bar = Foo::Bar.new

puts Foo::VERSION
puts bar.inspect
