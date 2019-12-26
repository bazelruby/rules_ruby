RubyLibrary = provider(
    fields = [
        "transitive_ruby_srcs",
        "ruby_incpaths",
        "rubyopt",
    ],
)

# A provider with one field, transitive_sources.
RubyApp = provider(
    fields = [
        "transitive_ruby_sources",
        "ruby_incpaths",
        "rubyopt",
        "bundled_gems",
    ],
)
