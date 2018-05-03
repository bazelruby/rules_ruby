load(
    "//ruby/private:host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)

def ruby_register_toolchains(version="host"):
  if version == "host":
    _ruby_host_runtime(
        name = "org_ruby_lang_ruby_host",
    )
  else:
    # TODO(yugui) support ruby interpereters in the current repo
    # TODO(yugui) support installing the specified version of ruby from source
    fail("TODO(yugui) support non-host interpreters for determinicity")
