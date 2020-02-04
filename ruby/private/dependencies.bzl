load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def ruby_rules_dependencies():
    if "bazel_skylib" not in native.existing_rules():
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
            ],
            sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
        )

    if "rules_pkg" not in native.existing_rules():
        # Use Grahams improved rules_zip version until google merges it into mainline.
        # https://github.com/bazelbuild/rules_pkg/pull/127
        http_archive(
            name = "rules_pkg",
            url = "https://github.com/grahamjenson/rules_pkg/archive/3e0cd514ad1cdd2d23ab3d427d34436f75060018.zip",
            sha256 = "85e26971904cbb387688bd2a9e87c105f7cd7d986dc1b96bb1391924479c5ef6",
            strip_prefix = "rules_pkg-3e0cd514ad1cdd2d23ab3d427d34436f75060018/pkg",
        )
