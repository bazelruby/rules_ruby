load(":constants.bzl", "RSPEC_ATTRS", "TOOLCHAIN_TYPE_NAME")
load(":binary.bzl", "ruby_binary_macro")

def _ruby_rspec(ctx):
    bundle = ctx.attr.bundle

    rspec_executable = ctx.file.spec_executable
    rspec_gem = Label("%s:rspec" % (bundle))
    args = ctx.attr.rspec_args + ctx.attr.args

    if ctx.attr.spec_target:
        spec_file = ctx.file.spec_target
        args.append(spec_file.path)

    return ruby_binary_macro(
        ctx,
        rspec_executable,
        ctx.attr.srcs + [rspec_executable],
        ctx.attr.deps + [rspec_gem],
        args,
    )

ruby_rspec_test = rule(
    implementation = _ruby_rspec,
    attrs = RSPEC_ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
