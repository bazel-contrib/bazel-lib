"""Unit tests for starlark helpers
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:expand_make_vars.bzl", "expand_variables")

def _variables_test_impl(ctx):
    env = unittest.begin(ctx)
    capture_subs = {}
    fake_ctx = struct(
        bin_dir = struct(path = "bazel-bin"),
        label = struct(workspace_name = "my-wksp", workspace_root = "my-wksp", package = "path/to", name = "target"),
        expand_make_variables = lambda attr, expr, subs: capture_subs.update(subs),
        build_file_path = "some/path/BUILD.bazel",
        version_file = struct(path = "bazel-out/volatile-status.txt"),
        info_file = struct(path = "bazel-out/stable-status.txt"),
        workspace_name = "my-wksp",
    )
    expand_variables(fake_ctx, "output=$(@D)")
    expected = {
        "@D": "bazel-bin/my-wksp/path/to",
        "RULEDIR": "bazel-bin/my-wksp/path/to",
        "BUILD_FILE_PATH": "some/path/BUILD.bazel",
        "VERSION_FILE": "bazel-out/volatile-status.txt",
        "INFO_FILE": "bazel-out/stable-status.txt",
        "TARGET": "@my-wksp//path/to:target",
        "WORKSPACE": "my-wksp",
    }
    asserts.equals(env, expected, capture_subs)
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
t0_test = unittest.make(_variables_test_impl)

def expand_make_vars_test_suite():
    unittest.suite("make_vars_tests", partial.make(t0_test, timeout = "short"))
