load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")
load(":providers.bzl", "RubyLibrary")

# Function passed to map_each above
def _to_short_path(f):
    return f.short_path

def _ruby_rubocop_impl(ctx):
    directory = ctx.attr.dir
    configs = ctx.attr.rubocop_configs
    autofix = ctx.attr.autofix
    srcs = ctx.attr.srcs
    deps = ctx.attr.deps

    args = ctx.actions.args()
    args.add_all(["-P", "-D"])

    if autofix:
        print("Will Run Rubocop in the Auto-Fixing mode...")
        args.add("-a")

    if configs:
        args.add_all(ctx.files.rubocop_configs, format_each = "-c %s", map_each = _to_short_path)

    print("rubocop args are ", args)

    ctx.actions.run(
        inputs = srcs,
        arguments = args,
        progress_message = "Running Rubocop...",
        executable = ctx.attr.main,
    )

_ATTRS = {
    "autofix": attr.bool(
        default = False,
    ),
    "rubocop_configs": attr.label_list(
        default = [":rubocop.yml"],
        allow_files = True,
    ),
    "dir": attr.string(
        default = "./",
    ),
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "rubyopt": attr.string_list(
    ),
    "main": attr.label(
        default = "@bundle//:bin/rubocop",
    ),
    "deps": attr.label_list(
        providers = [RubyLibrary],
    ),
    "_wrapper_template": attr.label(
        allow_single_file = True,
        default = "binary_wrapper.tpl",
    ),
    "_misc_deps": attr.label_list(
        allow_files = True,
        default = ["@bazel_tools//tools/bash/runfiles"],
    ),
}

ruby_rubocop = rule(
    attrs = _ATTRS,
    executable = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
    implementation = _ruby_rubocop_impl,
)
