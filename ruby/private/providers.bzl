RubyLibrary = provider(
    fields = [
        "transitive_ruby_srcs",
        "ruby_incpaths",
        "rubyopt",
    ],
)

RubyRuntimeContext = provider(
    doc = "Carries info required to execute Ruby Scripts",
    fields = [
        "ctx",
        "interpreter",
        "environment",
    ],
)

RubyGem = provider(
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
