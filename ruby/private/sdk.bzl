load(
    ":host_runtime.bzl",
    _rb_host_runtime = "rb_host_runtime",
)

def _register_host_runtime():
    _rb_host_runtime(name = "org_ruby_lang_ruby_host")

    native.register_toolchains(
        "@org_ruby_lang_ruby_host//:ruby_host",
    )

def rb_register_toolchains():
    """Registersr ruby toolchains in the WORKSPACE file."""
    _register_host_runtime()
