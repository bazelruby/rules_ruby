# Binary Rule for Gem #{name} version {version}
ruby_binary(
    name = "{label}",
    srcs = ["{full_path}"],
    main = "{full_path}",
    rubyopt = {rubyopts},
    visibility = ["//visibility:public"],
    deps = {deps},
)
