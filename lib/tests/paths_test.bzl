"""unit tests for paths"""

load("@bazel_skylib//lib:partial.bzl", "partial")
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

    asserts.equals(
        env,
        "../../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../repo/some/external/repo/short/path.txt",
            "some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../../../../repo/some/external/repo/short/path.txt",
            "some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "repo/some/external/repo/short/path.txt",
            "../some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "repo/some/external/repo/short/path.txt",
            "../../../../some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../../repo/some/external/repo/short/path.txt",
            "../some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../../../../repo/some/external/repo/short/path.txt",
            "../some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../repo/some/external/repo/short/path.txt",
            "../some/main/repo/short/path.txt",
        ),
    )

    asserts.equals(
        env,
        "../../../../repo/some/external/repo/short/path.txt",
        paths.relative_file(
            "../../../repo/some/external/repo/short/path.txt",
            "../../../some/main/repo/short/path.txt",
        ),
    )

    return unittest.end(env)

def _rlocation_path_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "bazel_skylib/LICENSE", paths.to_rlocation_path(ctx, ctx.file.f1))
    asserts.equals(env, "aspect_bazel_lib/lib/paths.bzl", paths.to_rlocation_path(ctx, ctx.file.f2))

    # deprecated naming
    asserts.equals(env, "bazel_skylib/LICENSE", paths.to_manifest_path(ctx, ctx.file.f1))
    asserts.equals(env, "aspect_bazel_lib/lib/paths.bzl", paths.to_manifest_path(ctx, ctx.file.f2))
    return unittest.end(env)

def _repository_relative_path_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "LICENSE", paths.to_repository_relative_path(ctx.file.f1))
    asserts.equals(env, "lib/paths.bzl", paths.to_repository_relative_path(ctx.file.f2))

    # deprecated naming
    asserts.equals(env, "LICENSE", paths.to_workspace_path(ctx.file.f1))
    asserts.equals(env, "lib/paths.bzl", paths.to_workspace_path(ctx.file.f2))
    return unittest.end(env)

def _output_relative_path_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "../../../external/bazel_skylib/LICENSE", paths.to_output_relative_path(ctx.file.f1))
    asserts.equals(env, "../../../lib/paths.bzl", paths.to_output_relative_path(ctx.file.f2))
    asserts.equals(env, "external/external_test_repo/test_a", paths.to_output_relative_path(ctx.file.f3))
    asserts.equals(env, "lib/tests/template.txt", paths.to_output_relative_path(ctx.file.f4))
    return unittest.end(env)

_ATTRS = {
    # source file in external repo
    "f1": attr.label(allow_single_file = True, default = "@bazel_skylib//:LICENSE"),
    # source file in current repo
    "f2": attr.label(allow_single_file = True, default = "//lib:paths.bzl"),
    # output file in external repo
    "f3": attr.label(allow_single_file = True, default = "@external_test_repo//:test_a"),
    # output file in current repo
    "f4": attr.label(allow_single_file = True, default = "//lib/tests:gen_template"),
}

relative_file_test = unittest.make(_relative_file_test_impl)
rlocation_path_test = unittest.make(_rlocation_path_test_impl, attrs = _ATTRS)
output_relative_path_test = unittest.make(_output_relative_path_test_impl, attrs = _ATTRS)
repository_relative_path_test = unittest.make(_repository_relative_path_test_impl, attrs = _ATTRS)

def paths_test_suite():
    unittest.suite(
        "paths_tests",
        partial.make(relative_file_test, timeout = "short"),
        partial.make(rlocation_path_test, timeout = "short"),
        partial.make(output_relative_path_test, timeout = "short"),
        partial.make(repository_relative_path_test, timeout = "short"),
    )
