"Helpers for making test assertions"

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib:utils.bzl", "default_timeout")

def assert_contains(name, actual, expected, size = None, timeout = None):
    """Generates a test target which fails if the file doesn't contain the string.

    Depends on bash, as it creates an sh_test target.

    Args:
        name: target to create
        actual: Label of a file
        expected: a string which should appear in the file
        size: the size attribute of the test target
        timeout: the timeout attribute of the test target
    """

    test_sh = "_{}_test.sh".format(name)

    write_file(
        name = "_" + name,
        out = test_sh,
        content = [
            "#!/usr/bin/env bash",
            "set -o errexit",
            "grep --fixed-strings '{}' $1".format(expected),
        ],
    )

    native.sh_test(
        name = name,
        srcs = [test_sh],
        args = ["$(rootpath %s)" % actual],
        size = size,
        timeout = default_timeout(size, timeout),
        data = [actual],
    )
