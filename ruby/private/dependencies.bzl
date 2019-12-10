load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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

    http_archive(
        name = "ruby_2_6_3",
        url = "https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz",
        sha256 = "577fd3795f22b8d91c1d4e6733637b0394d4082db659fccf224c774a2b1c82fb",
        strip_prefix = "ruby-2.6.3",
        # TODO might need to bring this in for bundle versions
        build_file = "@bazelruby_ruby_rules//ruby/private/rubybuild:ruby_v2_6_3.BUILD",
        patches = [
            "@bazelruby_ruby_rules//ruby/private/rubybuild:probes.h.patch",
            "@bazelruby_ruby_rules//ruby/private/rubybuild:enc.encinit.c.patch",
            "@bazelruby_ruby_rules//ruby/private/rubybuild:debug_counter.h.patch",
        ],
        patch_args = ["-p1"],
    )

    http_archive(
        name = "zlib",
        url = "https://zlib.net/zlib-1.2.11.tar.gz",
        sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
        strip_prefix = "zlib-1.2.11",
        build_file = "@bazelruby_ruby_rules//ruby/private/rubybuild:zlib.BUILD",
    )
