"""local_config_platform repository rule
"""

def _impl(rctx):
    rctx.file("constraints.bzl", content = rctx.read(rctx.attr._constraints_bzl))

    rctx.file("BUILD.bazel", content = rctx.read(rctx.attr._build_bazel) + """
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
bzl_library(
    name = "constraints",
    srcs = ["constraints.bzl"],
    visibility = ["//visibility:public"],
)
""")

local_config_platform = repository_rule(
    implementation = _impl,
    doc = """Generates a copy of the auto-generated @local_config_platform repository with an added bzl_library.
    
    This is useful for rules that want to load `HOST_CONSTRAINTS` from `@local_config_platform//:constraints.bzl` and
    also want to use stardoc for generating documentation.
    """,
    attrs = {
        "_constraints_bzl": attr.label(default = "@local_config_platform//:constraints.bzl"),
        "_build_bazel": attr.label(default = "@local_config_platform//:BUILD.bazel"),
    },
)
