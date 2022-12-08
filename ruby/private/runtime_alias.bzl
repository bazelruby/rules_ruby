load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")
load(":providers.bzl", "RubyRuntimeToolchainInfo")

# These rules expose the runtime targets of whichever toolchain has been resolved.

def _ruby_runtime_alias_impl(ctx):
    ruby = ctx.toolchains[TOOLCHAIN_TYPE_NAME].ruby_runtime
    return [
        DefaultInfo(
            runfiles = ctx.runfiles(transitive_files = depset(ruby.runtime)),
            files = depset(ruby.runtime),
        ),
        ruby,
    ]

ruby_runtime_alias = rule(
    implementation = _ruby_runtime_alias_impl,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)

def _ruby_headers_alias_impl(ctx):
    runtime = ctx.attr.runtime[RubyRuntimeToolchainInfo]
    target = runtime.headers
    return [
        ctx.attr.runtime[DefaultInfo],
        target[CcInfo],
        target[InstrumentedFilesInfo],
        target[OutputGroupInfo],
    ]

ruby_headers_alias = rule(
    implementation = _ruby_headers_alias_impl,
    attrs = {
        "runtime": attr.label(
            doc = "The runtime alias to use.",
            mandatory = True,
        ),
    },
)

def _ruby_interpreter_alias_impl(ctx):
    runtime = ctx.attr.runtime[RubyRuntimeToolchainInfo]
    target = runtime.interpreter
    output = ctx.actions.declare_file("ruby_interpreter")

    ctx.actions.symlink(
        output = output,
        target_file = target[DefaultInfo].files_to_run.executable,
        is_executable = True,
    )
    runfiles = ctx.attr.runtime[DefaultInfo].default_runfiles.merge(
        ctx.attr.runtime[DefaultInfo].data_runfiles,
    )

    return [
        DefaultInfo(
            files = target.files,
            runfiles = runfiles,
            executable = output,
        ),
    ]

ruby_interpreter_alias = rule(
    implementation = _ruby_interpreter_alias_impl,
    executable = True,
    attrs = {
        "runtime": attr.label(
            doc = "The runtime alias to use.",
            mandatory = True,
        ),
    },
)
