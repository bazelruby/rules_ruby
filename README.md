# Ruby Rules for Bazel Build System

[![Build Status](https://travis-ci.org/bazelruby/rules_ruby.svg?branch=master)](https://travis-ci.org/bazelruby/rules_ruby)

## Project Background and the Current Status

_Latest update: 11/8/2019._

This project was pioneered by [Yuki Yugui Sonoda](https://github.com/yugui) in February 2018, and has recently attracted the attention of other developers that are working on integrating large Ruby Codebases into the Mono-repos.

Together we hope to create `rules_ruby` repo that's will eventually be included into the list of Bazel tools under [github.com/bazelbuild](https://github.com/bazelbuild).

## Goals

Bazel is an opinionated framework, and it does so in order to deliver highly parallelizeable builds, extremely aggressive caching, and ultimately speed up the developer workflow with ruby apps considerably.

With the MVP version of Ruby Rules, our hope is that the following can be accomplished:

### Concrete Goals for the MVP version `0.1.0`

We'd like to be able to do the following:

- A ruby developer can introduce Bazel into their existing Rails App, Ruby Gem, Sinatra App -- all of which we collectively refer to as a "**Ruby App**".

- A developer should not need to spend more than 10 minutes setting it up.

- A developer can define a top level `BUILD` file for their app, which in turn will define targets such as executables, libraries, transient dependencies, bundled gems, and automated tests.

- If additional `BUILD` files are required in sub-folders, we will attempt to auto-generate them as needed.

- Once setup, a developer will **build their application** (which typically requires running bundle install, but may include additional steps like compiling static assets for a Rails Server) using Bazel, possibly benefiting from the global Cache that might already contain dependent gems build and installed by prior runs.

At the most basic level, a developer will now be able to:

- Run any executable within that application via `bazel run ...`
- Run the tests via `bazel test ...`
- Co-exist with othier Ruby Applications in the same mono repo

## USAGE

To enable bazel rules in your project, first you must create a file named `WORKSPACE` at the root of your ruby app. Note, that _you should ONLY have one `WORKSPACE` file per repo._

### Workspace File

In this file you will declare dependencies on the Ruby Rules contained in this repo:

```python
# File: ./WORKSPACE
# vi: ft=bazel

git_repository(
    name = "rules_ruby",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    tag = "v0.0.1",
)

load(
    "@rules_ruby//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_rules_dependencies()

ruby_register_toolchains()
```

### BUILD files

In addition to the singluar `WORKSPACE` file, you'll need to also drop `BUILD` files in any folder that might have unique targets and requirements.

#### Where do you need a BUILD file?

This is an excellent question.

Let's imagine you are building a Ruby Gem. Our hope is that we can auto-generate a BUILD file for your gem, drop it in your gem's root folder, and you can build/run/test your gem straight from that build file without doing anything particularly fancy.

A typical gem will have it's Ruby files in the `lib` folder, executables in either `bin` or `exe` folder, and tests in either `tests` or `specs`. Which means that for the most part we should just be albe to define all rules on how to build your gem in a single BUILD file at the top of your hierarchy.

Add `rb_library`, `rb_binary` or `rb_test` into your `BUILD` files.

```python
load(
    "@rules_ruby//ruby:defs.bzl",
    "rb_binary",
    "rb_library",
    "rb_test",
)

rb_library(
    name = "foo",
    srcs = ["lib/foo.rb"],
    includes = ["lib"],
)

rb_binary(
    name = "bar",
    srcs = ["bin/bar"],
    deps = [":foo"],
)

rb_test(
    name = "foo_test",
    srcs = ["test/foo_test.rb"],
    deps = [":foo"],
)
```

### Project Structure

Here is a sample project structure of a Ruby Gem that has been adapted to work with or without Bazel build system:

In the example below, I generated a skeleton for a blank Ruby Gem called `bazel-salad`:

```
.
├── BUILD
├── CODE_OF_CONDUCT.md
├── Gemfile
├── LICENSE.txt
├── README.md
├── Rakefile
├── WORKSPACE
├── bazel-salad.gemspec
├── bin
│   ├── console
│   └── setup
├── lib
│   ├── BUILD
│   └── bazel
│       ├── salad
│       │   └── version.rb
│       └── salad.rb
└── spec
    ├── BUILD
    ├── bazel
    │   └── salad_spec.rb
    └── spec_helper.rb
```

## API Reference

### `rb_library`

```
rb_library(
    name,
    deps,
    srcs,
    data,
    compatible_with,
    deprecation,
    distribs,
    features,
    licenses,
    restricted_to,
    tags,
    testonly,
    toolchains,
    visibility
)
```

### rb_binary

```
rb_binary(
    name, 
    deps, 
    srcs, 
    data, 
    main, 
    compatible_with, 
    deprecation, 
    distribs, 
    features, 
    licenses, 
    restricted_to, 
    tags, 
    testonly, 
    toolchains, 
    visibility, 
    args, 
    output_licenses
)
```

### rb_test

```
rb_test(
    name, 
    deps, 
    srcs, 
    data, 
    main, 
    compatible_with, 
    deprecation, 
    distribs, 
    features, 
    licenses, 
    restricted_to, 
    tags, 
    testonly, 
    toolchains, 
    visibility, 
    args, 
    size, 
    timeout, 
    flaky, 
    local, 
    shard_count
)
```

### bundle_install

Installs gems with Bundler, and make them available as a `rb_library`.

Example: `WORKSPACE`:

```python
git_repository(
    name = "ruby_rules",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    tag = "v0.1.0",
)

load(
    "@ ruby_rules//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_rules_dependencies()

ruby_register_toolchains()

load("@ ruby_rules//ruby:defs.bzl", "bundle_install")

bundle_install(
    name = "gems",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
```

Example: `lib/BUILD.bazel`:

```python
rb_library(
    name = "foo",
    srcs = ["foo.rb"],
    deps = ["@gems//:libs"],
)
```

```
bundle_install(name, gemfile, gemfile_lock)
```

NOTE: This rule never updates the `Gemfile.lock`. It is your responsibility to generate/update `Gemfile.lock`

## What's coming next

1. Building native extensions in gems with Bazel
2. Using a specified version of Ruby.
3. Building and releasing your gems with Bazel

## Copyright

Copyright © 2018 Yuki Yugui Sonoda & Contributors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
