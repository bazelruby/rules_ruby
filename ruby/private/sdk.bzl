load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)
load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:ruby_sandbox_runtime.bzl",
    "ruby_sandbox_runtime",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _install_ruby_26():
    http_archive(
        name = "ruby_sandbox",
        url = "https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz",
        sha256 = "577fd3795f22b8d91c1d4e6733637b0394d4082db659fccf224c774a2b1c82fb",
        strip_prefix = "ruby-2.6.3",
        # TODO might need to bring this in for bundle versions
        build_file = "@bazelruby_ruby_rules//ruby/private/ruby_sandbox_files:ruby_v2_6_3.BUILD",
        patches = [
            "@bazelruby_ruby_rules//ruby/private/ruby_sandbox_files:probes.h.patch",
            "@bazelruby_ruby_rules//ruby/private/ruby_sandbox_files:enc.encinit.c.patch",
            "@bazelruby_ruby_rules//ruby/private/ruby_sandbox_files:debug_counter.h.patch",
        ],
        patch_args = ["-p1"],
    )

    http_archive(
        name = "zlib",
        url = "https://zlib.net/zlib-1.2.11.tar.gz",
        sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
        strip_prefix = "zlib-1.2.11",
        build_file = "@bazelruby_ruby_rules//ruby/private/ruby_sandbox_files:zlib.BUILD",
    )


def _register_host_runtime():
    _ruby_host_runtime(name = "org_ruby_lang_ruby_toolchain")

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )


def _register_ruby_26_runtime():
    _install_ruby_26()

    ruby_sandbox_runtime(
        name = "org_ruby_lang_ruby_toolchain",
    )

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )

def ruby_register_toolchains(version = "host"):
    """Registersr ruby toolchains in the WORKSPACE file."""
    if version == "host":
        _register_host_runtime()
    elif version == "2.6":
        _register_ruby_26_runtime()
    else:
        fail("unknown ruby version in `ruby_register_toolchains`")
