load(":constants.bzl", "TOOLCHAIN_TYPE_NAME")
load(":providers.bzl", "RubyLibrary")
load(
    "//ruby/private/tools:deps.bzl",
    _transitive_deps = "transitive_deps",
)

def _to_manifest_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    else:
        return ("%s/%s" % (ctx.workspace_name, file.short_path))

def _rb_binary_impl(ctx):
    sdk = ctx.toolchains[TOOLCHAIN_TYPE_NAME].ruby_runtime
    interpreter = sdk.interpreter[DefaultInfo].files_to_run.executable

    main = ctx.file.main
    if not main:
        expected_name = "%s.rb" % ctx.attr.name
        for f in ctx.attr.srcs:
            if f.label.name == expected_name:
                main = f.files.to_list()[0]
                break
    if not main:
        fail(
            ("main must be present unless the name of the rule matches to " +
             "one of the srcs"),
            "main",
        )

    if sdk.is_host:
        interpreter_file_deps = []
        interpreter_trans_deps = []
    else:
        interpreter_file_deps = [interpreter]
        interpreter_trans_deps = [sdk.interpreter]

    executable = ctx.actions.declare_file(ctx.attr.name)
    deps = _transitive_deps(
        ctx,
        extra_files = interpreter_file_deps + [executable],
        extra_deps = interpreter_trans_deps,
    )

    rubyopt = reversed(deps.rubyopt.to_list())

    ctx.actions.expand_template(
        template = ctx.file._wrapper_template,
        output = executable,
        substitutions = {
            "{interpreter}": interpreter.short_path,
            "{loadpaths}": repr(deps.incpaths.to_list()),
            "{rubyopt}": repr(rubyopt),
            "{main}": repr(_to_manifest_path(ctx, main)),
        },
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        default_runfiles = deps.default_files,
        data_runfiles = deps.data_files,
    )]

_ATTRS = {
    "srcs": attr.label_list(
        allow_files = True,
    ),
    "deps": attr.label_list(
        providers = [RubyLibrary],
    ),
    "includes": attr.string_list(),
    "rubyopt": attr.string_list(),
    "data": attr.label_list(
        allow_files = True,
    ),
    "main": attr.label(
        allow_single_file = True,
    ),
    "_wrapper_template": attr.label(
        allow_single_file = True,
        default = "binary_wrapper.tpl",
    ),
}

rb_binary = rule(
    implementation = _rb_binary_impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)

rb_test = rule(
    implementation = _rb_binary_impl,
    attrs = _ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
