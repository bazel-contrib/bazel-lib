"""Unit tests for starlark helpers
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:expand_make_vars.bzl", "expand_variables")

def _variables_test_impl(ctx):
    env = unittest.begin(ctx)
    capture_subs = {}
    fake_ctx = struct(
        bin_dir = struct(path = "bazel-bin"),
        label = struct(
            workspace_root = "my-wksp",
            package = "path/to",
        ),
        expand_make_variables = lambda attr, expr, subs: capture_subs.update(subs),
    )
    expand_variables(fake_ctx, "output=$(@D)")
    expected = {"@D": "bazel-bin/my-wksp/path/to", "RULEDIR": "bazel-bin/my-wksp/path/to"}
    asserts.equals(env, expected, capture_subs)
    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
t0_test = unittest.make(_variables_test_impl)

def expand_make_vars_test_suite(name):
    unittest.suite(name, t0_test)
