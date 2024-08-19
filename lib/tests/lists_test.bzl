"""unit tests for lists"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:lists.bzl", "every", "filter", "find", "map", "once", "pick", "some", "unique")

def _every_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, every(lambda i: i.endswith(".js"), ["app.js", "lib.js"]), True)
    asserts.equals(env, every(lambda i: i.endswith(".ts"), ["app.js", "lib.ts"]), False)

    return unittest.end(env)

every_test = unittest.make(_every_test_impl)

def _filter_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, filter(lambda i: i.endswith(".js"), ["app.ts", "app.js", "lib.ts", "lib.js"]), ["app.js", "lib.js"])

    return unittest.end(env)

filter_test = unittest.make(_filter_test_impl)

def _find_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, find(lambda i: i.endswith(".js"), ["app.ts", "app.js", "lib.ts", "lib.js"]), (1, "app.js"))
    asserts.equals(env, find(lambda i: i.endswith(".exe"), ["app.ts", "app.js", "lib.ts", "lib.js"]), (-1, None))

    return unittest.end(env)

find_test = unittest.make(_find_test_impl)

def _map_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, map(lambda i: i * 2, [1, 2, 3]), [2, 4, 6])

    return unittest.end(env)

map_test = unittest.make(_map_test_impl)

def _once_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, once(lambda i: i == 1, [1, 2, 3]), True)
    asserts.equals(env, once(lambda i: i > 1, [1, 2, 3]), False)

    return unittest.end(env)

once_test = unittest.make(_once_test_impl)

def _pick_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, pick(lambda i: i > 1, [1, 2, 3]), 2)

    return unittest.end(env)

pick_test = unittest.make(_pick_test_impl)

def _some_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, some(lambda i: i.endswith(".js"), ["app.ts", "app.js"]), True)
    asserts.equals(env, some(lambda i: i.endswith(".js"), ["app.ts", "lib.ts"]), False)

    return unittest.end(env)

some_test = unittest.make(_some_test_impl)

def _unique_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, unique(["foo", {"bar": "baz"}, 42, {"bar": "baz"}, "foo"]), ["foo", {"bar": "baz"}, 42])

    return unittest.end(env)

unique_test = unittest.make(_unique_test_impl)

def lists_test_suite():
    unittest.suite(
        "lists_tests",
        partial.make(every_test, timeout = "short"),
        partial.make(filter_test, timeout = "short"),
        partial.make(find_test, timeout = "short"),
        partial.make(map_test, timeout = "short"),
        partial.make(once_test, timeout = "short"),
        partial.make(pick_test, timeout = "short"),
        partial.make(some_test, timeout = "short"),
        partial.make(unique_test, timeout = "short"),
    )
