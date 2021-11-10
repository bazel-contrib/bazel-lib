"""unit tests for paths"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:paths.bzl", "paths")

def _relative_file_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        "lib/requirements.in",
        paths.relative_file(
            "bazel/python/internal/pip/test/lib/requirements.in",
            "bazel/python/internal/pip/test/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "pip/test/lib/requirements.in",
        paths.relative_file(
            "bazel/python/internal/pip/test/lib/requirements.in",
            "bazel/python/internal/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "bazel/python/internal/pip/test/lib/requirements.in",
        paths.relative_file(
            "/bazel/python/internal/pip/test/lib/requirements.in",
            "/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "../requirements.in",
        paths.relative_file(
            "bazel/python/internal/pip/test/requirements.in",
            "bazel/python/internal/pip/test/lib/requirements.in",
        ),
    )

    asserts.equals(
        env,
        "../requirements.out",
        paths.relative_file(
            "bazel/python/internal/pip/test/requirements.out",
            "bazel/python/internal/pip/test/lib/requirements.in",
        ),
    )

    asserts.equals(
        env,
        "requirements.out",
        paths.relative_file(
            "bazel/python/internal/pip/example/service/requirements.out",
            "bazel/python/internal/pip/example/service/requirements.in",
        ),
    )

    asserts.equals(
        env,
        "../service/requirements.out",
        paths.relative_file(
            "bazel/python/internal/pip/example/service/requirements.out",
            "bazel/python/internal/pip/example/lib/requirements.in",
        ),
    )

    asserts.equals(
        env,
        "../lib/bar/requirements.in",
        paths.relative_file(
            "bazel/python/internal/pip/example/lib/bar/requirements.in",
            "bazel/python/internal/pip/example/service/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "../../../example/lib/bar/requirements.in",
        paths.relative_file(
            "bazel/python/internal/pip/example/lib/bar/requirements.in",
            "bazel/python/internal/pip/lib/example/service/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "requirements.in",
        paths.relative_file(
            "requirements.in",
            "requirements.out",
        ),
    )

    asserts.equals(
        env,
        "requirements.in",
        paths.relative_file(
            "/bazel/requirements.in",
            "/bazel/requirements.out",
        ),
    )

    asserts.equals(
        env,
        "../requirements.in",
        paths.relative_file(
            "/requirements.in",
            "/bazel/requirements.out",
        ),
    )

    return unittest.end(env)

def _runfiles_manifest_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "bazel_skylib/LICENSE", paths.to_manifest_path(ctx, ctx.file.f1))
    asserts.equals(env, "aspect_bazel_lib/lib/paths.bzl", paths.to_manifest_path(ctx, ctx.file.f2))
    return unittest.end(env)

relative_file_test = unittest.make(_relative_file_test_impl)
runfiles_manifest_test = unittest.make(_runfiles_manifest_test_impl,
attrs = {
    "f1": attr.label(allow_single_file = True, default = "@bazel_skylib//:LICENSE"),
    "f2": attr.label(allow_single_file = True, default = "//lib:paths.bzl"),
})

def paths_test_suite():
    unittest.suite(
        "paths_tests",
        relative_file_test,
        runfiles_manifest_test)
