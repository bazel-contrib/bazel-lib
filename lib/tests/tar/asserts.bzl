"Make shorter assertions"

load("@aspect_bazel_lib//lib:testing.bzl", "assert_contains")

def assert_tar_listing(name, actual, expected):
    actual_listing = "_{}_listing".format(name)

    native.genrule(
        name = actual_listing,
        srcs = [actual],
        outs = ["_{}.listing".format(name)],
        cmd = "$(BSDTAR_BIN) -tvf $(execpath {}) >$@".format(actual),
        toolchains = ["@bsd_tar//:resolved_toolchain"],
    )

    assert_contains(
        name = name,
        actual = actual_listing,
        expected = "\n".join(expected + [""]),
    )
