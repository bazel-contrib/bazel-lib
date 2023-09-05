"""unit tests for lists"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib/private:lists.bzl", "every", "filter", "find", "map", "once", "pick", "some")

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

def lists_test_suite():
    unittest.suite(
        "lists_tests",
        every_test,
        filter_test,
        find_test,
        map_test,
        once_test,
        pick_test,
        some_test,
    )
