# Ruby ZIP Package

This rule runs `bundle install --path vendor/bundle` and creates a zip with the sources + vendor/bundle.

```bazel

load(
    "@bazelruby_ruby_rules//ruby:defs.bzl",
    "ruby_package_zip",
)

ruby_package_zip(
    name = "ruby-lambda-package",
    srcs = [
        "Gemfile",
        "Gemfile.lock",
        "lib/lambda.rb",
        "template.yml",
    ],
)
```
