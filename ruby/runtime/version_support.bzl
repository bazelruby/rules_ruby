load("@bazel_skylib//lib:new_sets.bzl", "sets")
load(
    "@rules_ruby//ruby/private:constants.bzl",
    "SUPPORTED_VERSIONS",
)

def _major_minor_versions():
    """Filters supported versions to unique major/minor pairs"""
    versions = sets.make()
    for s in SUPPORTED_VERSIONS:
        if s.find(".") < 0:
            continue
        split = s.find(".", s.find(".") + 1)
        sets.insert(versions, s[0:split])
    return sorted(sets.to_list(versions))

def _filter(versions, prefix):
    filtered = []
    for v in versions:
        if v.startswith(prefix):
            filtered.append(v)
    return filtered

SUPPORTED_MAJOR_MINOR_VERSIONS = _major_minor_versions()
ALL_RUBY_MAJOR_MINOR_VERSIONS = _filter(SUPPORTED_MAJOR_MINOR_VERSIONS, "ruby-")
ALL_JRUBY_MAJOR_MINOR_VERSIONS = _filter(SUPPORTED_MAJOR_MINOR_VERSIONS, "jruby-")
