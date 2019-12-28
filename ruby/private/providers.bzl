RubyLibrary = provider(
    doc = "Default struct that holds information about a specific Ruby library, like a gem or an app",
    fields = [
        "transitive_ruby_srcs",
        "ruby_incpaths",
        "rubyopt",
    ],
)

RubyLibraryTransitiveSources = provider(
    doc = "Collection of transitive sources and data files based on RubyLibrary",
    fields = [
        "srcs",  # depset
        "incpaths",  # depset
        "rubyopt",  # depset
        "data_files",  # runfiles
        "default_files",  # runfiles
    ],
)
