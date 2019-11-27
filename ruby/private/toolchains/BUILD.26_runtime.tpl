load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

load(
    "{rules_ruby_workspace}//ruby:defs.bzl",
    "ruby_library",
    "ruby_toolchain",
)


###
# Sorbet Ruby
###

git_repository(
    name = "com_stripe_ruby_typer",
    remote = "https://github.com/sorbet/sorbet",
    commit = "4711cccbfcc59ba3178e3e4dd13c2e6c75c7ecd8",
)

http_archive(
  name = "ruby_2_6_3",
  url = "https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.3.tar.gz",
  sha256 = "577fd3795f22b8d91c1d4e6733637b0394d4082db659fccf224c774a2b1c82fb",
  strip_prefix = "ruby-2.6.3",
  # TODO might need to bring this in for bundle versions
  build_file = "@com_stripe_ruby_typer//third_party/ruby:ruby-2.6.BUILD",
  patches = [
      "@com_stripe_ruby_typer//third_party/ruby:probes.h.patch",
      "@com_stripe_ruby_typer//third_party/ruby:enc.encinit.c.patch",
      "@com_stripe_ruby_typer//third_party/ruby:debug_counter.h.patch",
  ],
  patch_args = ["-p1"],
)


###
# Toolchain
###

ruby_toolchain(
    name = "ruby_host",
    interpreter = "@ruby_2_6_3//:ruby",
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