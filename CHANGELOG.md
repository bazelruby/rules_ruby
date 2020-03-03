# 0.3.0 / 2020-03-02

[Total Changes since v0.2.0](https://github.com/bazelruby/rules_ruby/compare/v0.2.0...v0.3.0)

**2,221 additions and 631 deletions in 71 changed files.**

## Backwards Incompatible Changes

* Main workspace has been renamed from `bazelruby_ruby_rules` to `bazelruby_rules_ruby`
* Global function `ruby_register_toolchains` has been renamed to `rules_ruby_select_sdk`
* Global function `ruby_rules_dependencies` has been renamed to `rules_ruby_dependencies`
* `bundle_install` has been removed in favor of `ruby_bundle`.

## Other Changes

* Introduced `ruby_gem` rule for packaging Ruby sources into a RubyGem-compatible zip file. Note, the resulting file has `.zip` extension.
* Introduced `ruby_rubocop` rule for running rubocop in analysis mode or auto-correcting mode.
* Added an example gem workspace under `examples/example-gem`
* Default ruby used is now 2.7.0. We also now allow 2.7.0 to be built by Bazel.
* Bazelisk has been updated to 1.3.0
* Updated Bazel version from 2.0.0 to 2.1.0
* Updated gem versions in the Gemfile
* Changed how the `ruby_bundle` pulls gem's folders into the bundle to include additional files.
* Many other small changes, for full list [please see the diff](https://github.com/bazelruby/rules_ruby/compare/v0.2.0...v0.3.0).

# 0.2.0 / 2020-12-30

[Total Changes since v0.1.0](https://github.com/bazelruby/rules_ruby/compare/v0.1.0...v0.2.0)

# 0.1.0 / 2019-11-20

* Initial migration from [Yugui](https://github.com/yugui) rules ruby.