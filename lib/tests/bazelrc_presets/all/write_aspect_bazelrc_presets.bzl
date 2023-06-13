"Simple wrapper around write_aspect_bazelrc_presets for testing"

load("@aspect_bazel_lib//lib:bazelrc_presets.bzl", _write_aspect_bazelrc_presets = "write_aspect_bazelrc_presets")
load("@aspect_bazel_lib_host//:defs.bzl", "host")

def write_aspect_bazelrc_presets(**kwargs):
    if host.bazel_version[0] == "6":
        # Don't stamp this target out if we're testing against Bazel 5 or 7. The bazel6.bazelrc file is
        # deleted on CI when testing Bazel 5 which breaks analysis for this target. See
        # https://github.com/aspect-build/bazel-lib/blob/fff5f10ad8e6921a45816e256f588d8020b3f2ee/.github/workflows/ci.yaml#L145.
        _write_aspect_bazelrc_presets(**kwargs)
