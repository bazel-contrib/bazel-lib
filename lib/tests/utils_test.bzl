"Unit tests for test.bzl"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:utils.bzl", "utils")

def _to_label_test_impl(ctx):
    env = unittest.begin(ctx)

    # assert label/string comparisons work as expected
    asserts.true(env, "//some/label" != Label("//some/label"))
    asserts.true(env, "//some/label" != Label("//some/other/label"))
    asserts.true(env, Label("//some/label") == Label("//some/label"))
    asserts.true(env, "//some/label" != Label("//some/label"))
    asserts.true(env, "//some/label" != Label("//some/other/label"))

    # assert that to_label can convert from string to label
    asserts.true(env, utils.to_label("//hello/world") == Label("//hello/world:world"))
    asserts.true(env, utils.to_label("//hello/world:world") == Label("//hello/world:world"))

    # assert that to_label will handle a Label as an argument
    asserts.true(env, utils.to_label(Label("//hello/world")) == Label("//hello/world:world"))
    asserts.true(env, utils.to_label(Label("//hello/world:world")) == Label("//hello/world:world"))

    return unittest.end(env)

def _is_external_label_test_impl(ctx):
    env = unittest.begin(ctx)

    # assert that labels and strings that are constructed within this workspace (rh) return false
    asserts.false(env, utils.is_external_label("//some/label"))
    asserts.false(env, utils.is_external_label(Label("//some/label")))
    asserts.false(env, utils.is_external_label(Label("@aspect_bazel_lib//some/label")))
    asserts.false(env, ctx.attr.internal_with_workspace_as_string)

    # assert that labels and string that give a workspace return true
    asserts.true(env, utils.is_external_label(Label("@foo//some/label")))
    asserts.true(env, ctx.attr.external_as_string)

    return unittest.end(env)

to_label_test = unittest.make(_to_label_test_impl)
is_external_label_test = unittest.make(
    _is_external_label_test_impl,
    attrs = {
        "external_as_string": attr.bool(
            mandatory = True,
        ),
        "internal_with_workspace_as_string": attr.bool(
            mandatory = True,
        ),
    },
)

def utils_test_suite():
    unittest.suite("to_label_tests", to_label_test)

    is_external_label_test(
        name = "is_external_label_tests",
        external_as_string = utils.is_external_label("@foo//some/label"),
        internal_with_workspace_as_string = utils.is_external_label("@aspect_bazel_lib//some/label"),
    )
