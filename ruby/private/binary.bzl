load(":constants.bzl", "RUBY_ATTRS", "TOOLCHAIN_TYPE_NAME")
load(
    "//ruby/private/tools:deps.bzl",
    _transitive_deps = "transitive_deps",
)

def _to_manifest_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    else:
        return ("%s/%s" % (ctx.workspace_name, file.short_path))

# Having this function allows us to override otherwise frozen attributes
# such as main, srcs and deps. We use this in ruby_rspec_test rule by
# adding rspec as a main, and sources, and rspec gem as a dependency.
#
# There could be similar situations in the future where we might want
# to create a rule (eg, rubocop) that does exactly the same.
def ruby_binary_macro(ctx, main, srcs, deps, args):
    sdk = ctx.toolchains[TOOLCHAIN_TYPE_NAME].ruby_runtime
    interpreter = sdk.interpreter[DefaultInfo].files_to_run.executable

    if not main:
        expected_name = "%s.rb" % ctx.attr.name
        for f in srcs:
            if f.label.name == expected_name:
                main = f.files.to_list()[0]
                break
    if not main:
        fail(
            ("main must be present unless the name of the rule matches to " +
             "one of the srcs"),
            "main",
        )

    executable = ctx.actions.declare_file(ctx.attr.name)

    deps = _transitive_deps(
        ctx,
        extra_files = [executable],
        extra_deps = ctx.attr._misc_deps,
    )

    rubyopt = reversed(deps.rubyopt.to_list())

    ctx.actions.expand_template(
        template = ctx.file._wrapper_template,
        output = executable,
        substitutions = {
            "{loadpaths}": repr(deps.incpaths.to_list()),
            "{rubyopt}": repr(rubyopt),
            "{main}": repr(_to_manifest_path(ctx, main)),
            "{interpreter}": _to_manifest_path(ctx, interpreter),
        },
    )

    return [DefaultInfo(
        executable = executable,
        default_runfiles = deps.default_files,
        data_runfiles = deps.data_files,
    )]

def ruby_binary_impl(ctx):
    return ruby_binary_macro(
        ctx,
        ctx.file.main,
        ctx.attr.srcs,
        ctx.attr.deps,
        ctx.attr.args,
    )

ruby_binary = rule(
    implementation = ruby_binary_impl,
    attrs = RUBY_ATTRS,
    executable = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)

ruby_test = rule(
    implementation = ruby_binary_impl,
    attrs = RUBY_ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
