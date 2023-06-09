"""unit tests for string"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:strings.bzl", "chr", "hex", "ord")

def _ord_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, ord("a"), 97)
    asserts.equals(env, ord("b"), 98)
    asserts.equals(env, ord("/"), 47)
    asserts.equals(env, ord("c"), 99)
    asserts.equals(env, ord("x"), 120)
    asserts.equals(env, ord("@"), 64)
    asserts.equals(env, ord("%"), 37)
    asserts.equals(env, ord("$"), 36)
    asserts.equals(env, ord("+"), 43)

    return unittest.end(env)

ord_test = unittest.make(_ord_test_impl)

def _chr_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, chr(97), "a")
    asserts.equals(env, chr(98), "b")
    asserts.equals(env, chr(47), "/")
    asserts.equals(env, chr(99), "c")
    asserts.equals(env, chr(120), "x")
    asserts.equals(env, chr(64), "@")
    asserts.equals(env, chr(37), "%")
    asserts.equals(env, chr(36), "$")
    asserts.equals(env, chr(43), "+")

    return unittest.end(env)

chr_test = unittest.make(_chr_test_impl)

def _hex_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, hex(1111), "0x457")
    asserts.equals(env, hex(97), "0x61")
    asserts.equals(env, hex(1000000000000), "0xe8d4a51000")
    asserts.equals(env, hex(1), "0x1")

    # https://en.wikipedia.org/wiki/Signed_zero
    asserts.equals(env, hex(0), "0x0")
    asserts.equals(env, hex(-0), "0x0")
    asserts.equals(env, hex(-1234), "-0x4d2")
    asserts.equals(env, hex(-99999999), "-0x5f5e0ff")

    return unittest.end(env)

hex_test = unittest.make(_hex_test_impl)

def strings_test_suite():
    unittest.suite(
        "strings_tests",
        ord_test,
        chr_test,
        hex_test,
    )
