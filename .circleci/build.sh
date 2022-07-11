#!/usr/bin/env bash

set -e

[[ -d .circleci ]] && cd .circleci

RUBY_VERSION=$(cat ../.ruby-version)

echo
echo "Ruby version is $RUBY_VERSION"
echo

set -x 

docker build --platform linux/x86_64 . -t bazelruby/ruby-$RUBY_VERSION

docker push       bazelruby/ruby-$RUBY_VERSION

