# rules_ruby
Ruby rules for [Bazel](https://bazel.build).

## Status
Proof of Concept

## How to use

Add `ruby_register_toolchains` into your `WORKSPACE` file

```python
git_repository(
    name = "com_github_yugui_rules_ruby",
    remote = "https://github.com/yugui/rules_ruby.git",
    commit = "8378a0ba19ab7c6d751c440bc016d9af76da656c",
)

load("@com_github_yugui_rules_ruby//ruby:def.bzl", "ruby_register_toolchains")

ruby_register_toolchains()

```

Add `ruby_library` and `ruby_binary` into your `BUILD.bazel` files.

```python
ruby_library(
  name = "foo",
  srcs = ["lib/foo.rb"],
  includes = ["lib"],
)

ruby_binary(
  name = "bar",
  srcs = ["bin/bar"],
  deps = ["foo"],
)
```

## What's coming next
1. Support RubyGems with Bundler
2. Building native extensions in gems with Bazel
3. Building and releasing your gems with Bazel

## Copyright
Copyright 2018 Yuki Yugui Sonoda

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
