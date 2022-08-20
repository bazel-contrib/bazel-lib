"""unit tests for glob_match"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:glob_match.bzl", "glob_match")

def _glob_match_test(ctx, expr, matches, non_matches, mps_matches = None, mps_non_matches = None):
    """`mps sands for `match path segment`
    """
    env = unittest.begin(ctx)

    if mps_matches == None:
        mps_matches = matches

    if mps_non_matches == None:
        mps_non_matches = non_matches

    for path in matches:
        asserts.equals(env, True, glob_match(expr, path), "Expected expr '{}' to match on path '{}'".format(expr, path))

    for path in non_matches:
        asserts.equals(env, False, glob_match(expr, path), "Expected expr '{}' to _not_ match on path '{}'".format(expr, path))

    for path in mps_matches:
        asserts.equals(env, True, glob_match(expr, path, match_path_separator = True), "Expected expr '{}' with match_path_separator to match on path '{}'".format(expr, path))

    for path in mps_non_matches:
        asserts.equals(env, False, glob_match(expr, path, match_path_separator = True), "Expected expr '{}' with match_path_separator to _not_ match on path '{}'".format(expr, path))

    return unittest.end(env)

def _star(ctx):
    return _glob_match_test(
        ctx,
        "*",
        matches = ["express"],
        non_matches = ["@eslint/plugin-foo"],
        mps_matches = ["express", "@eslint/plugin-foo"],
        mps_non_matches = [],
    )

star_test = unittest.make(_star)

def _globstar(ctx):
    return _glob_match_test(ctx, "**", ["@eslint/plugin-foo", "express"], [])

globstar_test = unittest.make(_globstar)

def _qmark(ctx):
    return _glob_match_test(
        ctx,
        "?",
        matches = ["a", "b"],
        non_matches = ["/", "aa", "bb"],
        mps_matches = ["a", "b", "/"],
        mps_non_matches = ["aa", "bb"],
    )

qmark_test = unittest.make(_qmark)

def _qmark_qmark(ctx):
    return _glob_match_test(
        ctx,
        "??",
        matches = ["aa", "ba"],
        non_matches = ["/", "a", "b"],
    )

qmark_qmark_test = unittest.make(_qmark_qmark)

def _wrapped_qmark(ctx):
    return _glob_match_test(
        ctx,
        "f?n",
        matches = ["fun", "fin"],
        non_matches = ["funny", "fit", "bob", "f/n"],
        mps_matches = ["fun", "fin", "f/n"],
        mps_non_matches = ["funny", "fit", "bob"],
    )

wrapped_qmark_test = unittest.make(_wrapped_qmark)

def _mixed_wrapped_qmark(ctx):
    return _glob_match_test(
        ctx,
        "f?n*",
        matches = ["fun", "fin", "funny"],
        non_matches = ["fit", "bob", "f/n", "f/n/uny"],
        mps_matches = ["fun", "fin", "f/n", "funny", "f/n/uny"],
        mps_non_matches = ["fit", "bob"],
    )

mixed_wrapped_qmark_test = unittest.make(_mixed_wrapped_qmark)

def _ending_star(ctx):
    return _glob_match_test(ctx, "eslint-*", ["eslint-plugin-foo"], ["@eslint/plugin-foo", "express", "eslint", "-eslint"])

ending_star_test = unittest.make(_ending_star)

def _wrapping_star(ctx):
    return _glob_match_test(
        ctx,
        "*plugin*",
        matches = ["eslint-plugin-foo"],
        non_matches = ["@eslint/plugin-foo", "express"],
        mps_matches = ["eslint-plugin-foo", "@eslint/plugin-foo"],
        mps_non_matches = ["express"],
    )

wrapping_star_test = unittest.make(_wrapping_star)

def _wrapped_star(ctx):
    return _glob_match_test(ctx, "a*c", ["ac", "abc", "accc", "acacac", "a1234c", "a12c34c"], ["abcd"])

wrapped_star_test = unittest.make(_wrapped_star)

def _starting_star(ctx):
    return _glob_match_test(ctx, "*-positive", ["is-positive"], ["is-positive-not"])

starting_star_test = unittest.make(_starting_star)

def _mixed_trailing_globstar(ctx):
    return _glob_match_test(
        ctx,
        "foo*/**",
        matches = ["foo/fum/bar", "foostar/fum/bar"],
        non_matches = ["fo/fum/bar", "fostar/fum/bar", "foo", "foostar"],
    )

mixed_trailing_globstar_test = unittest.make(_mixed_trailing_globstar)

def _mixed_leading_globstar(ctx):
    return _glob_match_test(
        ctx,
        "**/foo*",
        matches = ["fum/bar/foo", "fum/bar/foostar"],
        non_matches = ["fum/bar/fo", "fum/bar/fostar", "foo", "foostar"],
    )

mixed_leading_globstar_test = unittest.make(_mixed_leading_globstar)

def _mixed_wrapping_globstar(ctx):
    return _glob_match_test(
        ctx,
        "**/foo*/**",
        matches = ["fum/bar/foo/fum/bar", "fum/bar/foostar/fum/bar"],
        non_matches = ["fum/bar/fo/fum/bar", "fum/bar/fostar/fum/bar", "foo", "foostar"],
    )

mixed_wrapper_globstar_test = unittest.make(_mixed_wrapping_globstar)

def glob_match_test_suite():
    unittest.suite(
        "glob_match_tests",
        partial.make(star_test, timeout = "short"),
        partial.make(globstar_test, timeout = "short"),
        partial.make(qmark_test, timeout = "short"),
        partial.make(qmark_qmark_test, timeout = "short"),
        partial.make(wrapped_qmark_test, timeout = "short"),
        partial.make(mixed_wrapped_qmark_test, timeout = "short"),
        partial.make(ending_star_test, timeout = "short"),
        partial.make(wrapping_star_test, timeout = "short"),
        partial.make(wrapped_star_test, timeout = "short"),
        partial.make(starting_star_test, timeout = "short"),
        partial.make(mixed_trailing_globstar_test, timeout = "short"),
        partial.make(mixed_leading_globstar_test, timeout = "short"),
        partial.make(mixed_wrapper_globstar_test, timeout = "short"),
    )
