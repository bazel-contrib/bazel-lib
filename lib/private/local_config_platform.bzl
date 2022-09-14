"""local_config_platform repository rule
"""

load(":repo_utils.bzl", "repo_utils")

def _impl(rctx):
    rctx.file("BUILD.bazel", """load(':constraints.bzl', 'HOST_CONSTRAINTS')
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ['//visibility:public'])

platform(name = 'host',
  # Auto-detected host platform constraints.
  constraint_values = HOST_CONSTRAINTS,
)

bzl_library(
    name = "constraints",
    srcs = ["constraints.bzl"],
    visibility = ["//visibility:public"],
)
""")

    # TODO: we can detect the host CPU in the future as well if needed;
    # see the repo_utils.platform(rctx) function for an example of this
    if repo_utils.is_darwin(rctx):
        rctx.file("constraints.bzl", content = """HOST_CONSTRAINTS = [
  '@platforms//cpu:x86_64',
  '@platforms//os:osx',
]
""")
    elif repo_utils.is_windows(rctx):
        rctx.file("constraints.bzl", content = """HOST_CONSTRAINTS = [
  '@platforms//cpu:x86_64',
  '@platforms//os:windows',
]
""")
    else:
        rctx.file("constraints.bzl", content = """HOST_CONSTRAINTS = [
  '@platforms//cpu:x86_64',
  '@platforms//os:linux',
]
""")

local_config_platform = repository_rule(
    implementation = _impl,
    doc = """Generates a repository in the same shape as the auto-generated @local_config_platform repository with an added bzl_library.
    
    This is useful for rules that want to load `HOST_CONSTRAINTS` from `@local_config_platform//:constraints.bzl` and
    also want to use stardoc for generating documentation.
    """,
)
