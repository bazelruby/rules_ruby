load(
    ":host_runtime.bzl",
    _ruby_host_runtime = "ruby_host_runtime",
)

def _register_host_runtime(rules_ruby_workspace):
  _ruby_host_runtime(
      name = "org_ruby_lang_ruby_host",
      rules_ruby_workspace = rules_ruby_workspace,
  )

  native.register_toolchains(
      "@org_ruby_lang_ruby_host//:ruby_host",
  )

def ruby_register_toolchains(rules_ruby_workspace="@com_github_yugui_rules_ruby"):
  """Registersr ruby toolchains in the WORKSPACE file.

  Args:
    rules_ruby_workspace: [INTERNAL USE]The workspace name of rules_ruby.

      Just a workaround of bazelbuild/bazel#3493. You rarely need to specify
      this attribute.
  """
  _register_host_runtime(rules_ruby_workspace)
