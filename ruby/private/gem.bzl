load(
    ":gemspec.bzl",
    _rb_gemspec = "rb_gemspec",
)
load(
    "@rules_pkg//:pkg.bzl",
    "pkg_zip",
)

def rb_gem(name, version, gem_name, srcs = [], **kwargs):
    _zip_name = "%s-%s" % (gem_name, version)
    _gemspec_name = name + "_gemspec"

    _rb_gemspec(
        name = _gemspec_name,
        gem_name = gem_name,
        version = version,
        **kwargs
    )

    pkg_zip(
        name = _zip_name,
        srcs = srcs + [":" + _gemspec_name],
        strip_prefix = "./",
    )

    native.alias(
        name = name,
        actual = ":" + _zip_name,
        visibility = ["//visibility:public"],
    )
