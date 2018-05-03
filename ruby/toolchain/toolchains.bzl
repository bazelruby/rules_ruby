load(
    "//ruby/private:host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)

load(
    "//ruby/private:toolchain.bzl",
    _ruby_toolchain = "ruby_toolchain",
)


def _declare_toolchain_repositories(version):
  """
  Registers the specified version of ruby runtime in the WORKSPACE file.
  """
  if version == "host":
    _ruby_host_runtime(
        name = "org_ruby_lang_ruby_host",
    )
  else:
    # TODO(yugui) support ruby interpereters in the current repo
    # TODO(yugui) support installing the specified version of ruby from source
    fail("TODO(yugui) support non-host interpreters for determinicity")

def _register_toolchains():
  native.register_toolchains(
      "@com_github_yugui_rules_ruby//ruby/toolchain:host",
  )

def ruby_register_toolchains(version="host"):
  _declare_toolchain_repositories(version)

def declare_toolchains():
  _ruby_toolchain(
      name = "ruby-host",
      # TODO(yugui) Detect the right constraints for the host
      host = None,
      interpreter = "@org_ruby_lang_ruby_host//:ruby",
      init_files = [
        #"@org_ruby_lang_ruby_host//:init_loadpath.rb",
        "@org_ruby_lang_ruby_host//:init_loadpath",
      ],
      runtime = "@org_ruby_lang_ruby_host//:runtime",
  )
