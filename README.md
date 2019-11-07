# Rules ruby
[![Build Status](https://travis-ci.org/yugui/rules_ruby.svg?branch=master)](https://travis-ci.org/yugui/rules_ruby)

Ruby rules for [Bazel](https://bazel.build).

## Status
Proof of Concept

## How to use

Add `ruby_rules_dependencies` and `ruby_register_toolchains` into your
`WORKSPACE` file.

```python
git_repository(
    name = "com_github_yugui_rules_ruby",
    remote = "https://github.com/yugui/rules_ruby.git",
    tag = "v0.1.0",
)

load(
    "@com_github_yugui_rules_ruby//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_rules_dependencies()

ruby_register_toolchains()
```

Add `ruby_library`, `ruby_binary` or `ruby_test` into your `BUILD.bazel` files.

```python
load(
    "@com_github_yugui_rules_ruby//ruby:defs.bzl",
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
### ruby_library
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

### ruby_binary
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

### ruby_test
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

### bundle_install
Installs gems with Bundler, and make them available as a `ruby_library`.

Example: `WORKSPACE`:

```python
git_repository(
    name = "com_github_yugui_rules_ruby",
    remote = "https://github.com/yugui/rules_ruby.git",
    tag = "v0.1.0",
)

load(
    "@com_github_yugui_rules_ruby//ruby:deps.bzl",
    "ruby_register_toolchains",
    "ruby_rules_dependencies",
)

ruby_register_toolchains()

ruby_register_toolchains()

load("@com_github_yugui_rules_ruby//ruby:defs.bzl", "bundle_install")

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
