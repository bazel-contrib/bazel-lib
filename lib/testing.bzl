"Helpers for making test assertions"

load("//lib:params_file.bzl", "params_file")
load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib:utils.bzl", "default_timeout")
load("//lib:jq.bzl", "jq")

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

def assert_outputs(name, actual, expected):
    """Assert that the default outputs of a target are the expected ones.

    Args:
        name: name of the resulting diff_test
        actual: string of the label to check the outputs
        expected: a list of rootpaths of expected outputs, as they would appear in a runfiles manifest
    """

    if not types.is_list(expected):
        fail("expected should be a list of strings")

    params_file(
        name = "_actual_" + name,
        data = [actual],
        args = ["$(rootpaths {})".format(actual)],
        out = "_{}_outputs.txt".format(name),
    )

    write_file(
        name = "_expected_ " + name,
        content = expected,
        out = "_expected_{}.txt".format(name),
    )

    diff_test(
        name = name,
        file1 = "_expected_ " + name,
        file2 = "_actual_" + name,
    )

def assert_json_matches(name, file1, file2, filter1 = ".", filter2 = "."):
    """Assert that the given json files have the same semantic content.

    Uses jq to filter each file. The default value of `"."` as the filter
    means to compare the whole file.

    See the [jq rule](./jq.md#jq) for more about the filter expressions as well as
    setup notes for the `jq` toolchain.

    Args:
        name: name of resulting diff_test target
        file1: a json file
        file2: another json file
        filter1: a jq filter to apply to file1
        filter2: a jq filter to apply to file2
    """
    name1 = "_{}_jq1".format(name)
    name2 = "_{}_jq2".format(name)
    jq(
        name = name1,
        srcs = [file1],
        filter = filter1,
    )

    jq(
        name = name2,
        srcs = [file2],
        filter = filter2,
    )

    diff_test(
        name = name,
        file1 = name1,
        file2 = name2,
        failure_message = "'{}' from {} doesn't match '{}' from {}".format(
            filter1,
            file1,
            filter2,
            file2,
        ),
    )
