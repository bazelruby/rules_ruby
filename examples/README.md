## Examples for `ruby_rules`

This directory is structured as a mini-monorepo with examples on how to bazel-enable Ruby Apps and Gems (TBD).

## Using Examples

This folder is it's own top-level Bazel Workspace, which currently contains the following targets:

```bash
$ bazel query //...:all
//apps/foo-bar/spec/foo:version_test
//apps/foo-bar/bin:show_version_test
//apps/foo-bar/bin:show_version
//apps/foo-bar/lib:foo
//apps/foo-bar/lib/foo:version
//apps/foo-bar/lib/foo:bar
```

You can then build the repo with

```bash
$ bazel build //...:all
```

And then run binary targets like so:

```bash
$ bazel run //apps/foo-bar/spec/foo:version_test
```

And test targets like so:

```bash
$ bazel test //apps/foo-bar/bin:show_version_test
```
