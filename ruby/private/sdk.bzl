load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)
load(
    "@bazelruby_ruby_rules//ruby/private/toolchains:ruby26_runtime.bzl",
    _ruby_26_runtime = "ruby_26_runtime",
)

def _register_host_runtime():
    _ruby_host_runtime(name = "org_ruby_lang_ruby_host")

    native.register_toolchains(
        "@org_ruby_lang_ruby_host//:ruby_host",
    )

def _register_ruby_26_runtime():
    _ruby_26_runtime(name = "org_ruby_lang_ruby_26")

    native.register_toolchains(
        "@org_ruby_lang_ruby_26//:ruby_host",
    )

def ruby_register_toolchains(version = "host"):
    """Registersr ruby toolchains in the WORKSPACE file."""
    if version == "host":
        _register_host_runtime()
    elif version == "2.6":
        _register_ruby_26_runtime()
    else:
        fail("unknown ruby version in `ruby_register_toolchains`")
