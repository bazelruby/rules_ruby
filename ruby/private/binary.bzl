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

def _get_gem_path(incpaths):
    """
    incpaths is a list of `<bundle_name>/lib/ruby/<version>/gems/<gemname>-<gemversion>/lib`
    The gem_path is `<bundle_name>/lib/ruby/<version>` so we can go from an incpath to the
    gem_path pretty easily without much additional work.
    """
    if len(incpaths) == 0:
        return ""
    incpath = incpaths[0]
    return incpath.rsplit("/", 3)[0]

# Having this function allows us to override otherwise frozen attributes
# such as main, srcs and deps. We use this in ruby_rspec_test rule by
# adding rspec as a main, and sources, and rspec gem as a dependency.
#
# There could be similar situations in the future where we might want
# to create a rule (eg, rubocop) that does exactly the same.
def ruby_binary_macro(ctx, main, srcs):
    sdk = ctx.toolchains[TOOLCHAIN_TYPE_NAME].ruby_runtime
    interpreter_info = sdk.interpreter[DefaultInfo]
    interpreter = interpreter_info.files_to_run.executable
    interpreter_runfiles = interpreter_info.default_runfiles.merge(interpreter_info.data_runfiles)

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
    wrapper = ctx.actions.declare_file(ctx.attr.name + "_wrapper")

    deps = _transitive_deps(
        ctx,
        extra_files = [executable, wrapper, interpreter],
        extra_deps = ctx.attr._misc_deps,
    )

    gem_path = _get_gem_path(deps.incpaths.to_list())

    gems_to_pristine = ctx.attr.force_gem_pristine

    rubyopt = reversed(deps.rubyopt.to_list())

    ctx.actions.expand_template(
        template = ctx.file._wrapper_template,
        output = wrapper,
        substitutions = {
            "{loadpaths}": repr(deps.incpaths.to_list()),
            "{rubyopt}": repr(rubyopt),
            "{main}": repr(_to_manifest_path(ctx, main)),
            "{gem_path}": gem_path,
            "{should_gem_pristine}": str(len(gems_to_pristine) > 0).lower(),
            "{gems_to_pristine}": " ".join(gems_to_pristine),
        },
    )

    ctx.actions.expand_template(
        template = ctx.file._runner_template,
        output = executable,
        substitutions = {
            "{main}": wrapper.short_path,
            "{interpreter}": interpreter.short_path,
            "{workspace_name}": ctx.label.workspace_name or ctx.workspace_name,
        },
        is_executable = True,
    )

    info = DefaultInfo(
        executable = executable,
        runfiles = deps.default_files
            .merge(deps.data_files)
            .merge(interpreter_runfiles)
            .merge(ctx.runfiles(files = [wrapper])),
    )

    return [info]

def ruby_binary_impl(ctx):
    return ruby_binary_macro(
        ctx,
        ctx.file.main,
        ctx.attr.srcs,
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
