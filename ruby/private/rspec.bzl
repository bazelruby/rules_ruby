load(
    ":constants.bzl",
    "DEFAULT_BUNDLE_NAME",
    "DEFAULT_RSPEC_ARGS",
    "DEFAULT_RSPEC_GEMS",
    "RSPEC_ATTRS",
    "TOOLCHAIN_TYPE_NAME",
)
load(":binary.bzl", "ruby_binary_macro")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

def ruby_rspec(
        name,
        srcs = [],
        specs = [],
        deps = [],
        size = "small",
        rspec_args = {},
        bundle = DEFAULT_BUNDLE_NAME,
        visibility = None,
        **kwargs):
    args_list = []

    args_dict = dicts.add(DEFAULT_RSPEC_ARGS, rspec_args)

    # We pass the respec_args as a dictionary so that you can overwrite
    # the default rspec arguments with custom ones.
    for option, value in [(option, value) for option, value in args_dict.items()]:
        if value != None:
            args_list.append("%s %s" % (option, value))
        else:
            args_list.append("%s" % (option))

    args_list += specs

    rspec_gems = ["%s:%s" % (bundle, gem) for gem in DEFAULT_RSPEC_GEMS]

    deps += rspec_gems

    ruby_rspec_test(
        name = name,
        visibility = visibility,
        args = args_list,
        srcs = srcs + specs,
        deps = deps,
        size = size,
        **kwargs
    )

def _ruby_rspec_test_impl(ctx):
    bundle = ctx.attr.bundle

    rspec_executable = ctx.file.rspec_executable

    return ruby_binary_macro(
        ctx,
        rspec_executable,
        ctx.attr.srcs,
    )

ruby_rspec_test = rule(
    implementation = _ruby_rspec_test_impl,
    attrs = RSPEC_ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
