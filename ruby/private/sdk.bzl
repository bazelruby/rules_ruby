load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)
load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:ruby_sandbox_runtime.bzl",
    "ruby_sandbox_runtime",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _register_host_runtime():
    _ruby_host_runtime(name = "org_ruby_lang_ruby_toolchain")

    native.register_toolchains(
        "@org_ruby_lang_ruby_toolchain//:toolchain",
    )


def _register_ruby_26_runtime():
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
