"""unit tests for base64"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:base64.bzl", "decode", "encode")
load("//lib/private:strings.bzl", "INT_TO_CHAR")

def _base64_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, encode(""), "")
    asserts.equals(env, decode(""), "")

    asserts.equals(env, encode("a"), "YQ==")
    asserts.equals(env, decode("YQ=="), "a")

    asserts.equals(env, encode("ab"), "YWI=")
    asserts.equals(env, decode("YWI="), "ab")

    asserts.equals(env, encode("abc"), "YWJj")
    asserts.equals(env, decode("YWJj"), "abc")

    asserts.equals(env, encode("abcd"), "YWJjZA==")
    asserts.equals(env, decode("YWJjZA=="), "abcd")

    asserts.equals(env, encode("hello world"), "aGVsbG8gd29ybGQ=")
    asserts.equals(env, decode("aGVsbG8gd29ybGQ="), "hello world")

    test_strings = [
        "",
        "1",
        "12",
        "123",
        "1234",
        "this is a really long test string",
        "\0\1\2\3\4\5\6\7\376\377",  # short string containing unreadable chars
        "".join(INT_TO_CHAR),  # string of all possible 256 chars
    ]
    for s in test_strings:
        asserts.equals(env, decode(encode(s)), s)

    return unittest.end(env)

base64_test = unittest.make(_base64_test_impl)

def base64_test_suite():
    unittest.suite(
        "base64_tests",
        base64_test,
    )
