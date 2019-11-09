# Repository rules
load("//ruby/toolchain:toolchains.bzl", _ruby_register_toolchains = "ruby_register_toolchains")
load("//ruby/private:library.bzl", _rb_library = "rb_library")
load("//ruby/private:binary.bzl", _rb_binary = "rb_binary")
load("//ruby/private:binary.bzl", _rb_test = "rb_test")
load("//ruby/private:bundle.bzl", _rb_bundle = "rb_bundle")

load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

ruby_register_toolchains = _ruby_register_toolchains
rb_library = _rb_library
rb_test = _rb_test
rb_bundle = _rb_bundle

def rb_binary(name = None, **kwargs):
  _rb_binary(
    name = name,
    **kwargs
  )
#
#  pkg_tar(
#    name = name + '_deploy',
#    extension = '.tar.gz',
#    package_dir = name,
#    srcs = [name],
#    strip_prefix = './',
#    )
