load(
    ":constants.bzl",
    "DEFAULT_BUNDLE_NAME",
    "DEFAULT_RSPEC_ARGS",
    "DEFAULT_RSPEC_GEMS",
    "RSPEC_ATTRS",
    "TOOLCHAIN_TYPE_NAME",
)
load(":binary.bzl", "ruby_binary_macro")

def ruby_rspec(
        name,
        srcs,
        specs,
        deps = None,
        size = "small",
        rspec_args = None,  # This is expected to be a dictionary
        bundle = DEFAULT_BUNDLE_NAME,
        visibility = None,
        **kwargs):
    if specs == None:
        specs = []

    if srcs == None:
        srcs = []

    if rspec_args == None:
        rspec_args = {}

    args_list = []

    args_dict = {}
    args_dict.update(DEFAULT_RSPEC_ARGS)
    args_dict.update(rspec_args)

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
    deps.append("%s:bin" % bundle)

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
    return ruby_binary_macro(
        ctx,
        ctx.file.rspec_executable,
        ctx.attr.srcs,
    )

ruby_rspec_test = rule(
    implementation = _ruby_rspec_test_impl,
    attrs = RSPEC_ATTRS,
    test = True,
    toolchains = [TOOLCHAIN_TYPE_NAME],
)
