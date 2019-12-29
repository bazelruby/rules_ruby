## RulesRuby Toolking for RubyGems and Bundler



USAGE:
    rules_ruby_gem.rb [gem[:version]] [ options ]

DESCRIPTION
    Downloads and Install a gem in the repository or in the Bazel's
    build folder, Used by bundle_install.rb to install bundler itself.

EXAMPLE:
    # This will install to ./vendor/bundle/rspec-3.2.0
    rules_ruby_gem.rb rspec:3.2.0 -g vendor/bundle -s https://rubygems.org

    # This will install to ~/.gems/ruby/2.5.0/gems/sym-2.8.1
    lib/rules_ruby/gemset.rb -n sym -v 2.8.1 -g ~/.gems -p

OPTIONS:

    -n, --gem-name=NAME[:VERSION]    Name of the gem to install. May include the
                                     version after the ":".
    -v, --gem-version=N.Y.X          Gem version to install, optional.
    -s, --sources URL1,URL2..        Optional list of URIs to look for gems at
    -g, --gem-home=PATH              Directory where the gem should be installed.
    -p, --nested-path                If set, the gem will be installed under the gem-path provided,
                                     but in a deeply nested folder corresponding to a ruby standard.

                                     For instance, if GEM_HOME is "./vendor/bundle", and -p is set, then
                                     the resulting gem folder will be the following path (for rspec-core):
                                     ./vendor/bundle/ruby/2.5.0/gems/rspec-core-3.9.0
                                     assuming Ruby 2.5.* version.
    -h, --help                       Prints this help


USAGE:
  ruby_bundle.rb [options]

DESCRIPTION:
  This utility reads a Gemfile.lock passed in as an argument,
  and generates Bazel Build file for the Bundler (separately),
  as well as for each Gem in the Gemfile.lock (including transitive
  dependencies).

OPTIONS:

    -l, --gemfile-lock=FILE          Path to the Gemfile.lock
    -o, --output_file=FILE           Path to the generated BUILD file
    -B, --skip-buildifier            Do not run buildifier on the generated file.
    -r, --repo=NAME                  Name of the repository
    -w, --workspace=NAME             Name of the workspace
    -p, --bundle-path=PATH           Where to install Gems relative to current
                                     directory. Defaults to vendor/bundle
    -e, --excludes=JSON              JSON formatted hash with keys as gem names,
                                     and values as arrays of glob patterns.
    -v, --verbose                    Print verbose info
    -h, --help                       Prints this help

