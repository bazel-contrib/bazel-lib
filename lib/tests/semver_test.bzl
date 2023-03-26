"Unit tests for semvers"

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:semver.bzl", "semver")
load("//lib/private:semver.bzl", "make")

def _parse_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, make("1", "2", "3"), semver.parse("1.2.3"))
    asserts.equals(env, make("1", "2", "3", v = True), semver.parse("v1.2.3"))
    asserts.equals(env, make("1", "23", "49"), semver.parse("1.23.49"))
    asserts.equals(env, make("0", "0", "0"), semver.parse("0.0.0"))
    asserts.equals(env, make("0", "0", "0"), semver.parse("0.0.0"))

    asserts.equals(env, make("1", "2", "3", "a"), semver.parse("1.2.3-a"))
    asserts.equals(env, make("1", "2", "3", "alpha.1"), semver.parse("1.2.3-alpha.1"))
    asserts.equals(env, make("1", "2", "3", "alpha.12-foo.bar"), semver.parse("1.2.3-alpha.12-foo.bar"))

    asserts.equals(env, make("1", "0", "0", build_metadata = "abc123"), semver.parse("1.0.0+abc123"))
    asserts.equals(env, make("1", "0", "0", "alpha.4", build_metadata = "abc.12-3"), semver.parse("1.0.0-alpha.4+abc.12-3"))

    asserts.true(env, semver.parse("1.2.3-alpha1").prerelease)
    asserts.false(env, semver.parse("1.2.3").prerelease)

    return unittest.end(env)

def _key_test_impl(ctx):
    env = unittest.begin(ctx)

    v1_0_0__alpha_1 = make("1", "0", "0", "alpha.1")
    v1_0_0__alpha_2 = make("1", "0", "0", "alpha.2")
    v1_0_0__45 = make("1", "0", "0", "45")
    v1_0_0__4a5 = make("1", "0", "0", "4a5")
    v1_0_0 = make("1", "0", "0")
    v1_0_0_plus_1 = make("1", "0", "0", build_metadata = "1")
    v1_1_0 = make("1", "1", "0")
    v1_1_1 = make("1", "1", "1")
    v2_0_0 = make("2", "0", "0")

    # Lower major before higher major
    asserts.equals(env, [v1_0_0, v2_0_0], sorted([v2_0_0, v1_0_0], key = semver.key))

    # Lower minor before higher minor
    asserts.equals(env, [v1_0_0, v1_1_0], sorted([v1_1_0, v1_0_0], key = semver.key))

    # Lower patch before higher patch
    asserts.equals(env, [v1_1_0, v1_1_1], sorted([v1_1_1, v1_1_0], key = semver.key))

    # Prerelease before release
    asserts.equals(env, [v1_0_0__alpha_1, v1_0_0__alpha_2], sorted([v1_0_0__alpha_2, v1_0_0__alpha_1], key = semver.key))

    # Lower numeric prerelease segment before higher numeric segment
    asserts.equals(env, [v1_0_0__alpha_1, v1_0_0], sorted([v1_0_0, v1_0_0__alpha_1], key = semver.key))

    # Numeric prerelease segment before alphanumeric segment
    asserts.equals(env, [v1_0_0__45, v1_0_0__alpha_1], sorted([v1_0_0__alpha_1, v1_0_0__45], key = semver.key))
    asserts.equals(env, [v1_0_0__45, v1_0_0__4a5], sorted([v1_0_0__4a5, v1_0_0__45], key = semver.key))

    # Build metadata does not affect precedence
    asserts.equals(env, [v1_0_0, v1_0_0_plus_1], sorted([v1_0_0, v1_0_0_plus_1], key = semver.key))
    asserts.equals(env, [v1_0_0_plus_1, v1_0_0], sorted([v1_0_0_plus_1, v1_0_0], key = semver.key))

    return unittest.end(env)

parse_test = unittest.make(
    _parse_test_impl,
    attrs = {},
)

key_test = unittest.make(
    _key_test_impl,
    attrs = {},
)

def semver_test_suite():
    unittest.suite("semver_tests", parse_test, key_test)
