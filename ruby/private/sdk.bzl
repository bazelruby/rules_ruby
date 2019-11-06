load(
    ":host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)

def _register_host_runtime():
  _ruby_host_runtime(name = "org_ruby_lang_ruby_host")

  native.register_toolchains(
      "@org_ruby_lang_ruby_host//:ruby_host",
  )

def ruby_register_toolchains():
  """Registersr ruby toolchains in the WORKSPACE file."""
  _register_host_runtime()
