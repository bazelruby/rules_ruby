<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

* [Status:](#status)
* [Usage](#usage)
* [Rules](#rules)
  * [ruby_library](#ruby_library)
  * [ruby_binary](#ruby_binary)
  * [ruby_test](#ruby_test)
  * [bundle_install](#bundle_install)
* [What's coming next](#whats-coming-next)
* [Contributing](#contributing)
  * [Setup](#setup)
    * [Using the Script](#using-the-script)
    * [OS-Specific Setup](#os-specific-setup)
      * [Issues During Setup](#issues-during-setup)
  * [Developing Rules](#developing-rules)
  * [Running Tests](#running-tests)
    * [Test Script](#test-script)
  * [Linter](#linter)
* [Copyright](#copyright)

<!-- /TOC -->

### Build Status

| Build | Status |
|---------:	|---------------------------------------------------------------------------------------------------------------------------------------------------	|
| CircleCI Develop: 	| [![CircleCI](https://circleci.com/gh/bazelruby/rules_ruby/tree/develop.svg?style=svg)](https://circleci.com/gh/bazelruby/rules_ruby/tree/develop) 	|
| CircleCI Default: 	| [![CircleCI](https://circleci.com/gh/bazelruby/rules_ruby.svg?style=svg)](https://circleci.com/gh/bazelruby/rules_ruby) 	|
| Develop: 	| [![Build Status](https://travis-ci.org/bazelruby/rules_ruby.svg?branch=develop)](https://travis-ci.org/bazelruby/rules_ruby) 	|
| Master: 	| [![Build Status](https://travis-ci.org/bazelruby/rules_ruby.svg?branch=master)](https://travis-ci.org/bazelruby/rules_ruby) 	|


# Rules Ruby

Ruby rules for [Bazel](https://bazel.build).

## Status:

**Work in progress.**

We have a guide on [Building your first Ruby Project](https://github.com/bazelruby/rules_ruby/wiki/Build-your-ruby-project) on the Wiki. We encourage you to check it out.

## Usage

Add `ruby_rules_dependencies` and `ruby_register_toolchains` into your `WORKSPACE` file.

```python
# To get the latest, grab the 'develop' branch.

git_repository(
    name = "bazelruby_ruby_rules",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    branch = "develop",
)

load(
    "@bazelruby_ruby_rules//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_rules_dependencies()

ruby_register_toolchains()
```

Add `ruby_library`, `ruby_binary` or `ruby_test` into your `BUILD.bazel` files.

```python
load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_binary",
    "ruby_library",
    "ruby_test",
)

ruby_library(
    name = "foo",
    srcs = ["lib/foo.rb"],
    includes = ["lib"],
)

ruby_binary(
    name = "bar",
    srcs = ["bin/bar"],
    deps = [":foo"],
)

ruby_test(
    name = "foo_test",
    srcs = ["test/foo_test.rb"],
    deps = [":foo"],
)
```

## Rules

The following diagram attempts to capture the implementation behind `ruby_library` that depends on the result of `bundle install`, and a `ruby_binary` that depends on both:

![Ruby Rules](docs/img/ruby_rules.png)


### `ruby_library`

<pre>
ruby_library(name, deps, srcs, data, compatible_with, deprecation, distribs, features, licenses, restricted_to, tags, testonly, toolchains, visibility)
</pre>

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <code>List of Labels, optional</code>
        <p>
          List of <code>.rb</code> files.
        </p>
        <p>At least <code>srcs</code> or <code>deps</code> must be present</p>
      </td>
    </tr>
    <tr>
      <td><code>deps</code></td>
      <td>
        <code>List of labels, optional</code>
        <p>
          List of targets that are required by the <code>srcs</code> Ruby
          files.
        </p>
        <p>At least <code>srcs</code> or <code>deps</code> must be present</p>
      </td>
    </tr>
    <tr>
      <td><code>includes</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of paths to be added to <code>$LOAD_PATH</code> at runtime.
          The paths must be relative to the the workspace which this rule belongs to.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>rubyopt</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of options to be passed to the Ruby interpreter at runtime.
        </p>
        <p>
          NOTE: <code>-I</code> option should usually go to <code>includes</code> attribute.
        </p>
      </td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td colspan="2">And other <a href="https://docs.bazel.build/versions/master/be/common-definitions.html#common-attributes">common attributes</a></td>
    </tr>
  </tbody>
</table>

### `ruby_binary`

<pre>
ruby_binary(name, deps, srcs, data, main, compatible_with, deprecation, distribs, features, licenses, restricted_to, tags, testonly, toolchains, visibility, args, output_licenses)
</pre>

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <code>List of Labels, required</code>
        <p>
          List of <code>.rb</code> files.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>deps</code></td>
      <td>
        <code>List of labels, optional</code>
        <p>
          List of targets that are required by the <code>srcs</code> Ruby
          files.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>main</code></td>
      <td>
        <code>Label, optional</code>
        <p>The entrypoint file. It must be also in <code>srcs</code>.</p>
        <p>If not specified, <code><var>$(NAME)</var>.rb</code> where <code>$(NAME)</code> is the <code>name</code> of this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>includes</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of paths to be added to <code>$LOAD_PATH</code> at runtime.
          The paths must be relative to the the workspace which this rule belongs to.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>rubyopt</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of options to be passed to the Ruby interpreter at runtime.
        </p>
        <p>
          NOTE: <code>-I</code> option should usually go to <code>includes</code> attribute.
        </p>
      </td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td colspan="2">And other <a href="https://docs.bazel.build/versions/master/be/common-definitions.html#common-attributes">common attributes</a></td>
    </tr>
  </tbody>
</table>

### `ruby_test`

<pre>
ruby_test(name, deps, srcs, data, main, compatible_with, deprecation, distribs, features, licenses, restricted_to, tags, testonly, toolchains, visibility, args, size, timeout, flaky, local, shard_count)
</pre>

<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>srcs</code></td>
      <td>
        <code>List of Labels, required</code>
        <p>
          List of <code>.rb</code> files.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>deps</code></td>
      <td>
        <code>List of labels, optional</code>
        <p>
          List of targets that are required by the <code>srcs</code> Ruby
          files.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>main</code></td>
      <td>
        <code>Label, optional</code>
        <p>The entrypoint file. It must be also in <code>srcs</code>.</p>
        <p>If not specified, <code><var>$(NAME)</var>.rb</code> where <code>$(NAME)</code> is the <code>name</code> of this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>includes</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of paths to be added to <code>$LOAD_PATH</code> at runtime.
          The paths must be relative to the the workspace which this rule belongs to.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>rubyopt</code></td>
      <td>
        <code>List of strings, optional</code>
        <p>
          List of options to be passed to the Ruby interpreter at runtime.
        </p>
        <p>
          NOTE: <code>-I</code> option should usually go to <code>includes</code> attribute.
        </p>
      </td>
    </tr>
  </tbody>
  <tbody>
    <tr>
      <td colspan="2">And other <a href="https://docs.bazel.build/versions/master/be/common-definitions.html#common-attributes">common attributes</a></td>
    </tr>
  </tbody>
</table>

### `bundle_install`

Installs gems with Bundler, and make them available as a `ruby_library`.

Example: `WORKSPACE`:

```python
git_repository(
    name = "bazelruby_ruby_rules",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    tag = "v0.1.0",
)

load(
    "@bazelruby_ruby_rules//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_rules_dependencies()

ruby_register_toolchains()

load("@bazelruby_ruby_rules//ruby:defs.bzl", "bundle_install")

bundle_install(
    name = "gems",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
```

Example: `lib/BUILD.bazel`:

```python
ruby_library(
    name = "foo",
    srcs = ["foo.rb"],
    deps = ["@gems//:libs"],
)
```

<pre>
bundle_install(name, gemfile, gemfile_lock)
</pre>
<table class="table table-condensed table-bordered table-params">
  <colgroup>
    <col class="col-param" />
    <col class="param-description" />
  </colgroup>
  <thead>
    <tr>
      <th colspan="2">Attributes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>name</code></td>
      <td>
        <code>Name, required</code>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr>
      <td><code>gemfile</code></td>
      <td>
        <code>Label, required</code>
        <p>
          The <code>Gemfile</code> which Bundler runs with.
        </p>
      </td>
    </tr>
    <tr>
      <td><code>gemfile_lock</code></td>
      <td>
        <code>Label, required</code>
          <p>The <code>Gemfile.lock</code> which Bundler runs with.</p>
          <p>NOTE: This rule never updates the <code>Gemfile.lock</code>. It is your responsibility to generate/update <code>Gemfile.lock</code></p>
      </td>
    </tr>
  </tbody>
</table>

## What's coming next

1. Building native extensions in gems with Bazel
2. Using a specified version of Ruby.
3. Building and releasing your gems with Bazel

## Contributing

We welcome contributions to RulesRuby. Please make yourself familiar with the [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md) document.

You may notice that there is more than one Bazel WORKSPACE inside this repo. There is one in `examples/simple_script` for instance, because
we use this example to validate and test the rules. So be mindful whether your current directory contains `WORKSPACE` file or not.

### Setup

#### Using the Script

You will need Homebrew installed prior to running the script.

After that, cd into the top level folder and run the setup script in your Terminal:

```bash
❯ bin/setup
```

This runs a complete setup, shouldn't take too long. You can explore various script options with the `help` command:

```bash
❯ bin/setup help
USAGE
  # without any arguments runs a complete setup.
  bin/setup

  # alternatively, a sub-setup function name can be passed:
  bin/setup [ gems | git-hook | help | os-specific | main | remove-git-hook ]

DESCRIPTION:
  Runs full setup without any arguments.

  Accepts one optional argument — one of the actions that typically run
  as part of setup, with one exception — remove-git-hook.
  This action removes the git commit hook installed by the setup.

EXAMPLES:
    bin/setup — runs the entire setup.
```

#### OS-Specific Setup

Note that the setup contains `os-specific` section. This is because there are two extension scripts:

 * `bin/setup-linux`
 * `bin/setup-darwin`

Those will install Bazel and everything else you need on either platform. In fact, we use the linux version on CI.

##### Issues During Setup

**Please report any errors to `bin/setup` as Issues on Github. You can assign them to @kigster.**

### Developing Rules

Besides making yourself familiar with the existing code, and [Bazel documentation on writing rules](https://docs.bazel.build/versions/master/skylark/concepts.html), you might want to follow this order:

  1. Setup dev tools as described in the [setup](#Setup) section.
  3. hack, hack, hack...
  4. Make sure all tests pass — you can run a single command for that (but see more on it [below](#test-script).

    ```bash
    bin/test-suite
    ```

OR you can run individual Bazel test commands from the inside.

   * `bazel test //...`
   * `cd examples/simple_script && bazel test //...`

  4. Open a pull request in Github, and please be as verbose as possible in your description.

In general, it's always a good idea to ask questions first — you can do so by creating an issue.

### Running Tests

After running setup, and since this is a bazel repo you can use Bazel commands:

```bazel
bazel build //...:all
bazel query //...:all
bazel test //...:all
```

But to run tests inside each sub-WORKSPACE, you will need to repeat that in each sub-folder. Luckily, there is a better way.

#### Test Script

This script runs all tests (including sub-workspaces) when ran without arguments:

```bash
bin/test-suite
```

Run it with `help` command to see other options, and to see what parts you can run individually. At the moment they are:

```bash
# alternatively, a partial test name can be passed:
bin/test-suite [ all | bazel-info | buildifier | help | rspec | rubocop | simple-script |  workspace ]
```

On a MacBook Pro it takes about 3 minutes to run.

### Linter

We are using RuboCop for ruby and Buildifier for Bazel. Both are represented by a single script `bin/linter`, which just like the scripts above runs ALL linters when ran without arguments, accepts `help` commnd, and can be run on a subset of linting strategies:

```bash
bin/linter
```

The following are the partial linting functions you can run:

```bash
# alternatively, a partial linter name can be passed:
bin/linter [ all | buildifier | help | rubocop ]
```

## Copyright

© 2018-2019 Yuki Yugui Sonoda & BazelRuby Authors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
