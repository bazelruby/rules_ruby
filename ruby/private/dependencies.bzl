"""
Dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":constants.bzl", "RULES_RUBY_WORKSPACE_NAME")

def rules_ruby_dependencies():
    if "bazel_skylib" not in native.existing_rules():
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            ],
            sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
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

    # Register placeholders for the system ruby.
    native.bind(
        name = "rules_ruby_system_jruby_implementation",
        actual = "%s//:missing_jruby_implementation" % RULES_RUBY_WORKSPACE_NAME,
    )
    native.bind(
        name = "rules_ruby_system_ruby_implementation",
        actual = "%s//:missing_ruby_implementation" % RULES_RUBY_WORKSPACE_NAME,
    )
    native.bind(
        name = "rules_ruby_system_no_implementation",
        actual = "%s//:missing_no_implementation" % RULES_RUBY_WORKSPACE_NAME,
    )
