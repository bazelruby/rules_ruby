load(
    "//ruby/private/rubygems:shared.bzl",
    "DEFAULT_BUNDLER_VERSION",
    "TOOLS_RUBY_GEMSET",
    "rubygems_sources_csv",
)

# Installs arbitrary gem/version combo to any location specified by gem_home
# The tool used here is lib/rules_ruby/gemset.rb
def install_gem(
        ctx,
        interpreter,
        gem_name,
        gem_version,
        gem_home,
        rubygems_sources,
        environment = {},
        # If true, gem is installed under #{gem_home}/ruby/#{ruby_version}/gems/#{gem-name}-#{gem-version}
        # If false, gem is installed under #{gem_home} directly.
        use_nested_path = True):
    args = [
        interpreter,
        TOOLS_RUBY_GEMSET,
        gem_name + ":" + gem_version,
        "-g",
        gem_home,
        "-s",
        rubygems_sources_csv(rubygems_sources),
    ]

    if use_nested_path:
        args.append("-p")

    # print("installing gem with args\n", args)

    result = ctx.execute(
        args,
        environment = environment,
    )

    print(result.stdout)

    if result.return_code:
        message = "Failed to evaluate ruby snippet with {}: {}".format(
            interpreter,
            result.stderr,
        )
        fail(message)

def install_gems(
        ctx,
        interpreter,
        gems,
        gem_home,
        rubygems_sources,
        environment = {}):
    for gem_name, gem_version in [(gem_name, gem_version) for gem_name, gem_version in ctx.attr.gems.items()]:
        result = install_gem(
            ctx,
            interpreter,
            gem_name,
            gem_version,
            gem_home,
            rubygems_sources,
            environment,
        )

        gem_info = "gem {} (v{}): %s%s".format(gem_name, gem_version)
        if result.return_code:
            fail("Failed to install " % (gem_info, result.stdout, result.stderr))
        else:
            print("%s installed successfully" % (gem_info))

def install_bundler(
        ctx,
        interpreter,
        gem_home,
        rubygems_sources,
        environment):
    if "bundler" in ctx.attr.gems.keys():
        bundler_version = ctx.attr.gems["bundler"]
    else:
        bundler_version = DEFAULT_BUNDLER_VERSION

    print("Installing BUNDLER version", bundler_version)

    install_gem(
        ctx,
        interpreter,
        "bundler",
        bundler_version,
        gem_home,
        rubygems_sources,
        environment,
        False,
    )

def generate_gemfile(
        ctx,
        gems,
        rubygems_sources,
        gemfile):
    content = "# frozen_string_literal: true\n\n"
    for source in rubygems_sources:
        content += "source \"%s\"\n" % (source)

    content += "\n\n"

    for gem_name, gem_version in [(gem_name, gem_version) for gem_name, gem_version in gems.items()]:
        content += "gem '%s', '~> %s'\n" % (gem_name, gem_version)

    print("writing Gemfile: \n", content)
    ctx.file(
        gemfile,
        content,
    )
