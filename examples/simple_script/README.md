# Simple Script Example

This Workspace includes a simple ruby script that includes and external gem and an internal library

### Bundle

Update gemfile using:

```
gem instal bundler
bundle lock --update
```

### Running Rubocop

Your Gemfile incldues RuboCop, but you can run it via Bazel:

```
bazel run :rubocop -- $(pwd)/* -a
```