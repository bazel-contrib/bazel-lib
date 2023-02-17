"""local_config_platform repository rule
"""

load(":repo_utils.bzl", "repo_utils")

def _impl(rctx):
    rctx.file("BUILD.bazel", """load(':constraints.bzl', 'HOST_CONSTRAINTS')

package(default_visibility = ['//visibility:public'])

platform(name = 'host',
  # Auto-detected host platform constraints.
  constraint_values = HOST_CONSTRAINTS,
)

exports_files([
  # Export constraints.bzl for use in downstream bzl_library targets.
  'constraints.bzl',
])
""")

    [os, cpu] = repo_utils.platform(rctx).split("_")
    cpu_constraint = "@platforms//cpu:{0}".format("x86_64" if cpu == "amd64" else cpu)
    os_constraint = "@platforms//os:{0}".format("osx" if os == "darwin" else os)

    rctx.file("constraints.bzl", content = """HOST_CONSTRAINTS = [
  '{0}',
  '{1}',
]
""".format(cpu_constraint, os_constraint))

local_config_platform = repository_rule(
    implementation = _impl,
    doc = """Generates a repository in the same shape as the auto-generated @local_config_platform repository with an added bzl_library.

    This is useful for rules that want to load `HOST_CONSTRAINTS` from `@local_config_platform//:constraints.bzl` and
    also want to use stardoc for generating documentation.
    """,
)
