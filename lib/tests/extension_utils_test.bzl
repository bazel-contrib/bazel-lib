"Unit tests for module extension utils"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:extension_utils.bzl", "highest_compatible_toolchain_version")

def _highest_compatible_toolchain_version_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "1.2.0", highest_compatible_toolchain_version("1.2.0", ["1.2.0"]))
    asserts.equals(env, "1.4.5", highest_compatible_toolchain_version("1.2.0", ["1.0.0", "1.4.5", "1.2.0", "1.1.1"]))
    asserts.equals(env, "v1.0.0", highest_compatible_toolchain_version("v1.0.0-alpha1", ["v1.0.0", "v1.0.0-alpha1"]))

    return unittest.end(env)

highest_compatible_toolchain_version_test = unittest.make(
    _highest_compatible_toolchain_version_test_impl,
    attrs = {},
)

def extension_utils_test_suite():
    unittest.suite("extension_utils_tests", highest_compatible_toolchain_version_test)
