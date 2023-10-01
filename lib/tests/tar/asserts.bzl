"Make shorter assertions"

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# buildifier: disable=function-docstring
def assert_tar_listing(name, actual, expected):
    actual_listing = "_{}_listing".format(name)
    expected_listing = "_{}_expected".format(name)

    native.genrule(
        name = actual_listing,
        srcs = [actual],
        outs = ["_{}.listing".format(name)],
        cmd = "$(BSDTAR_BIN) -tvf $(execpath {}) >$@".format(actual),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    write_file(
        name = expected_listing,
        out = "_{}.expected".format(name),
        content = expected + [""],
    )

    diff_test(
        name = name,
        file1 = actual_listing,
        file2 = expected_listing,
    )
