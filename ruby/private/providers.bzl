RubyLibrary = provider(
    fields = [
        "transitive_ruby_srcs",
        "ruby_incpaths",
        "rubyopt",
    ],
)

Ruby = provider(
    doc = ""
    fields = [
        "path",
        "interpreter_name",
        "interpreter_realpath",
        "eval",
        "rbconfig",
        "expand_rbconfig",
        "_ctx",
    ],
)
