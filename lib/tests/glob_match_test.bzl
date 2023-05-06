"""unit tests for glob_match"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:glob_match.bzl", "glob_match", "is_glob")

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

def _basic(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, True, glob_match("a", "a"), "single directory")
    asserts.equals(env, True, glob_match("a/", "a/"), "trailing slash single directory")
    asserts.equals(env, True, glob_match("/a", "/a"), "leading slash single directory")
    asserts.equals(env, True, glob_match("/a/", "/a/"), "leading slash and trailing slash single directory")

    asserts.equals(env, True, glob_match("a/b", "a/b"), "nested directory")
    asserts.equals(env, True, glob_match("a/b/", "a/b/"), "trailing slash nested directory")
    asserts.equals(env, True, glob_match("/a/b", "/a/b"), "leading slash nested directory")
    asserts.equals(env, True, glob_match("/a/b/", "/a/b/"), "leading and trailing slash nested directory")

    return unittest.end(env)

basic_test = unittest.make(_basic)

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

def _trailing_star(ctx):
    return _glob_match_test(
        ctx,
        "x/*",
        matches = ["x/y", "x/y.z"],
        non_matches = ["x", "x/y/z"],
        mps_matches = ["x/y/z"],
        mps_non_matches = ["x"],
    )

trailing_star_test = unittest.make(_trailing_star)

def _globstar(ctx):
    return _glob_match_test(ctx, "**", ["@eslint/plugin-foo", "express"], [])

globstar_test = unittest.make(_globstar)

def _globstar_slash(ctx):
    return _glob_match_test(ctx, "**/*", ["@eslint/plugin-foo", "express"], [])

globstar_slash_test = unittest.make(_globstar_slash)

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

def _leading_star_test(ctx):
    return _glob_match_test(
        ctx,
        "*/foo.*",
        matches = ["fum/foo.x", "a/foo.bcd"],
        non_matches = ["foo.x", "a/b/foo.x", "a/foo"],
        mps_matches = ["fum/foo.x", "a/b/foo.x", "a/foo.bcd"],
        mps_non_matches = ["foo.x", "a/foo"],
    )

leading_star_test = unittest.make(_leading_star_test)

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
        matches = ["foo/fum/bar", "foostar/fum/bar", "foo/a", "foob/c", "foo/", "fooa/"],
        non_matches = ["fo/fum/bar", "fostar/fum/bar", "foo", "foostar", "afoo", "b/foo/c"],
    )

mixed_trailing_globstar_test = unittest.make(_mixed_trailing_globstar)

def _mixed_leading_globstar(ctx):
    return _glob_match_test(
        ctx,
        "**/foo*",
        matches = ["fum/bar/foo", "fum/bar/foostar", "foo", "foostar", "as/foo"],
        non_matches = ["fum/bar/fo", "fum/bar/fostar"],
    )

mixed_leading_globstar_test = unittest.make(_mixed_leading_globstar)

def _mixed_leading_globstar2(ctx):
    return _glob_match_test(
        ctx,
        "**/*foo",
        matches = ["fum/bar/foo", "fum/bar/starfoo", "foo", "xfoo"],
        non_matches = ["fum/bar/foox", "fum/bar/foo/y"],
    )

mixed_leading_globstar2_test = unittest.make(_mixed_leading_globstar2)

def _mixed_wrapping_globstar(ctx):
    return _glob_match_test(
        ctx,
        "**/foo*/**",
        matches = ["fum/bar/foo/fum/bar", "fum/bar/foostar/fum/bar", "foo/a", "foob/c", "foo/"],
        non_matches = ["fum/bar/fo/fum/bar", "fum/bar/fostar/fum/bar", "foo", "foostar"],
    )

mixed_wrapper_globstar_test = unittest.make(_mixed_wrapping_globstar)

def _all_of_ext(ctx):
    return _glob_match_test(
        ctx,
        "**/*.tf",
        matches = ["a.tf", "a/b.tf", "ab/cd/e.tf"],
        non_matches = ["a/b.tfg", "a/tf", "a/b.tf/g"],  #TODO: "a/.tf", ".tf"
    )

all_of_ext_test = unittest.make(_all_of_ext)

def _all_of_name(ctx):
    return _glob_match_test(
        ctx,
        "**/foo",
        matches = ["a/b/c/foo", "foo/foo", "a/foo/foo", "foo"],
        non_matches = ["foox", "foo/x"],
    )

all_of_name_test = unittest.make(_all_of_name)

def _is_glob(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, False, is_glob(""))
    asserts.equals(env, False, is_glob("/"))
    asserts.equals(env, False, is_glob("."))
    asserts.equals(env, False, is_glob("./"))
    asserts.equals(env, False, is_glob(".."))
    asserts.equals(env, False, is_glob("../"))
    asserts.equals(env, False, is_glob("/./."))
    asserts.equals(env, False, is_glob("/../."))
    asserts.equals(env, False, is_glob("/a/b/c/d"))
    asserts.equals(env, False, is_glob("/a/."))

    asserts.equals(env, True, is_glob("*"))
    asserts.equals(env, True, is_glob("**"))
    asserts.equals(env, True, is_glob("?"))
    asserts.equals(env, True, is_glob("/*"))
    asserts.equals(env, True, is_glob("/**"))
    asserts.equals(env, True, is_glob("/?"))
    asserts.equals(env, True, is_glob(".*"))
    asserts.equals(env, True, is_glob(".?"))
    asserts.equals(env, True, is_glob("./foo/**/bar"))
    asserts.equals(env, True, is_glob("*.txt"))
    asserts.equals(env, True, is_glob("a/?.txt"))

    return unittest.end(env)

is_glob_test = unittest.make(_is_glob)

def glob_match_test_suite():
    unittest.suite(
        "glob_match",
        partial.make(basic_test, timeout = "short"),
        partial.make(star_test, timeout = "short"),
        partial.make(trailing_star_test, timeout = "short"),
        partial.make(globstar_test, timeout = "short"),
        partial.make(globstar_slash_test, timeout = "short"),
        partial.make(qmark_test, timeout = "short"),
        partial.make(qmark_qmark_test, timeout = "short"),
        partial.make(wrapped_qmark_test, timeout = "short"),
        partial.make(mixed_wrapped_qmark_test, timeout = "short"),
        partial.make(leading_star_test, timeout = "short"),
        partial.make(ending_star_test, timeout = "short"),
        partial.make(wrapping_star_test, timeout = "short"),
        partial.make(wrapped_star_test, timeout = "short"),
        partial.make(all_of_ext_test, timeout = "short"),
        partial.make(all_of_name_test, timeout = "short"),
        partial.make(starting_star_test, timeout = "short"),
        partial.make(mixed_trailing_globstar_test, timeout = "short"),
        partial.make(mixed_leading_globstar_test, timeout = "short"),
        partial.make(mixed_leading_globstar2_test, timeout = "short"),
        partial.make(mixed_wrapper_globstar_test, timeout = "short"),
    )

    unittest.suite(
        "is_glob",
        partial.make(is_glob_test, timeout = "short"),
    )
