load(":bundler.bzl", "install_bundler")
load("//ruby/private:constants.bzl", "RULES_RUBY_WORKSPACE_NAME")
load("//ruby/private/toolchains:repository_context.bzl", "ruby_repository_context")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")




def _ruby_26_runtime_impl(ctx):
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

    ctx.template(
        "BUILD.bazel",
        ctx.attr._buildfile_template,
        substitutions = {
            "{rules_ruby_workspace}": RULES_RUBY_WORKSPACE_NAME,
        },
        executable = False,
    )

ruby_26_runtime = repository_rule(
    implementation = _ruby_26_runtime_impl,
    attrs = {
        "_init_loadpath_rb": attr.label(
            default = "%s//:ruby/tools/init_loadpath.rb" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_buildfile_template": attr.label(
            default = "%s//ruby/private/toolchains:BUILD.26_runtime.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
        "_interpreter_wrapper_template": attr.label(
            default = "%s//ruby/private/toolchains:interpreter_wrapper.tpl" % (
                RULES_RUBY_WORKSPACE_NAME
            ),
            allow_single_file = True,
        ),
    },
)
