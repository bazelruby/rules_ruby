ruby_library(
    name = "bundler_setup",
    srcs = ["{bundle_path}/lib/bundler/setup.rb"],
)

ruby_library(
    name = "all",
    srcs = glob(
        include = ["{bundle_path}/**/*"] + [
            "Gemfile",
            "Gemfile.lock",
        ],
        exclude_directories = 0,
    ),
    rubyopt = {rubyopts},
    deps = [":bundler_setup"],
)

ruby_library(
    name = "gems",
    srcs = glob(["{gem_prefix}/**/*"]) + [
        "Gemfile",
        "Gemfile.lock",
    ],
    rubyopt = {rubyopts},
    deps = [":bundler_setup"],
)

filegroup(
    name = "binstubs",
    srcs = glob(
        include = ["bin/**/*"],
        exclude_directories = 0,
    ),
    data = [":gems"],
)

ruby_library(
    name = "bundler",
    srcs = glob(["bundler/**/*"]),
    rubyopt = {rubyopts},
)

#—————————————————————————————————————————————————————————————————————————————————
# Filegroup that includes all *.gemspec files
# Not sure how useful this is....

filegroup(
    name = "gemspecs",
    srcs = glob(
        include = ["{gem_prefix}/*/*.gemspec"],
        exclude_directories = 0,
    ),
    visibility = ["//visibility:public"],
)
