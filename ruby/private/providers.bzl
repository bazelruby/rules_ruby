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
        "version",
    ],
)
