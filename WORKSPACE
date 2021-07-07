workspace(name = "bazelruby_rules_ruby")

load("@//ruby:deps.bzl", "rules_ruby_dependencies", "rules_ruby_select_sdk")

rules_ruby_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@bazel_skylib//lib:versions.bzl", "versions")

versions.check("3.4.1")

rules_ruby_select_sdk("3.0.1")

local_repository(
    name = "bazelruby_rules_ruby_ruby_tests_testdata_another_workspace",
    path = "ruby/tests/testdata/another_workspace",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# installing go for buildifier
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "8663604808d2738dc615a2c3eb70eba54a9a982089dd09f6ffe5d0e75771bc4f",
    urls = [
        "https://github.com/bazelbuild/rules_go/releases/download/v0.23.6/rules_go-v0.23.6.tar.gz",
    ],
)

git_repository(
    name = "bazel_gazelle",
    commit = "c00612418c4dbc9f3cd35fe71fe1147748048b69",
    remote = "https://github.com/bazelbuild/bazel-gazelle",
)

git_repository(
    name = "com_google_protobuf",
    commit = "6c61c1e63b9be3c36db6bed19032dfc0d63aadda",
    remote = "https://github.com/protocolbuffers/protobuf",
    shallow_since = "1558721209 -0700",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains(go_version = "1.14.6")

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

# rules_docker

http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "4521794f0fba2e20f3bf15846ab5e01d5332e587e9ce81629c7f96c793bb7036",
    strip_prefix = "rules_docker-0.14.4",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.4/rules_docker-v0.14.4.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
)

container_pull(
    name = "ruby_base_container",
    digest = "sha256:da560e130d6a4b75b099e932a98331ec3b2420b914d51a88edc4fe3c60aee9b1",  # alpine linux/amd64
    registry = "docker.io",
    repository = "library/ruby",
)

load("@bazelruby_rules_ruby//ruby:defs.bzl", "ruby_bundle")

ruby_bundle(
    name = "bundle",
    bundler_version = "2.1.4",
    excludes = {
        "mini_portile": ["test/**/*"],
    },
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

rules_pkg_dependencies()
