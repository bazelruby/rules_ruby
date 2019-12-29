#!/usr/bin/env ruby
# frozen_string_literal: true

BUNDLE_SETUP = 'vendor/bundle/bundler/setup'

dir = File.dirname(__FILE__)
if File.exist?("#{dir}/#{BUNDLE_SETUP}.rb")
  require_relative 'vendor/bundle/bundler/setup'
end

require 'oj'
require 'colored2'

def handler(event:, context:)
  Oj.dump(
    statusCode: context[:status],
    contentType: context[:content_type],
    body: handler_body(event)
  )
end

private

def handler_body(event)
  <<~BODY.gsub(/^\s+/, '')
    <html>
    <head>
      <title>#{event[:title]}</title>
    </head>
    <body>
      <h1>#{event[:header]}</h1>
      <blockquote>#{event[:body]}</blockquote>
    </body>
    </html>
  BODY
end

public

if $PROGRAM_NAME == __FILE__
  puts handler(
    event: {
      header: 'Welcome to Lambda!',
      title: 'Lambda Demo',
      body: 'Lambdas are cool. And so are you!'
    },
    context: {
      status: 200,
      content_type: 'text/html'
    }
  )
end
