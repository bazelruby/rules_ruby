"""
Provider Structs
"""

RubyLibraryInfo = provider(
    fields = [
        "transitive_ruby_srcs",
        "ruby_incpaths",
        "rubyopt",
    ],
)

RubyRuntimeInfo = provider(
    doc = "Carries info required to execute Ruby Scripts",
    fields = [
        "ctx",
        "interpreter",
        "environment",
    ],
)

RubyRuntimeToolchainInfo = provider(
    doc = "Information about a Ruby interpreter, related commands and libraries",
    fields = {
        "interpreter": "A label which points the Ruby interpreter",
        "bundler": "A label which points bundler command",
        "runtime": "A list of labels which points runtime libraries",
        "headers": "A list of labels which points to the ruby headers",
        "rubyopt": "A list of strings which should be passed to the interpreter as command line options",
    },
)

RubyGemInfo = provider(
    doc = "Carries info required to package a ruby gem",
    fields = [
        "ctx",
        "gem_author_emails",
        "gem_authors",
        "gem_runtime_dependencies",
        "gem_description",
        "gem_development_dependencies",
        "gem_homepage",
        "gem_name",
        "gem_summary",
        "gem_version",
    ],
)
