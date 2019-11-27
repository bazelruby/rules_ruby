load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)

package(default_visibility = ["//visibility:public"])

# init_loadpath file
filegroup(
    name = "init_loadpath",
    srcs = ["init_loadpath.rb"],
    data = ["loadpath.lst"],
)

# bundler file and requirements
filegroup(
    name = "bundler",
    srcs = ["bundler/exe/bundler"],
    data = glob(["bundler/**/*.rb"]),
)

# all files
filegroup(
    name = "runtime",
    srcs = glob(
        include = ["**/*"],
        exclude = [
            "init_loadpath.rb",
            "loadpath.lst",
            "BUILD.bazel",
            "WORKSPACE",
        ],
    ),
)

# definition of the ruby binary
sh_binary(
    name = "ruby_bin",
    srcs = ["ruby"],
    data = [":runtime"],
)

###
# Toolchain
###

ruby_toolchain(
    name = "ruby_host",
    interpreter = "//:ruby_bin",
    bundler = "//:bundler",
    init_files = ["//:init_loadpath"],
    rubyopt = [
        "-I../org_ruby_lang_ruby_host/bundler/lib",
    ],
    runtime = "//:runtime",
    rules_ruby_workspace = "{rules_ruby_workspace}",
    # TODO(yugui) Extract platform info from RbConfig
    # exec_compatible_with = [],
    # target_compatible_with = [],
)

###
# Not sure what these do here
###

cc_import(
    name = "libruby",
    hdrs = glob({hdrs}),
    static_library = {static_library},
    shared_library = {shared_library},
)

cc_library(
    name = "headers",
    includes = {includes},
    hdrs = glob({hdrs}),
)