#!/usr/bin/env bash

set -ex

docker build . -t bazelruby/ruby-2.6.5
docker push       bazelruby/ruby-2.6.5

