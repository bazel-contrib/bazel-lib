""" tests for the resource_set functions """

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//lib:resource_sets.bzl", "resource_set", "resource_set_for")

def _call_resource_set(value):
    fake_ctx = struct(resource_set = value)
    return resource_set(fake_ctx)("", "")

def _resource_set_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, None, resource_set(struct(resource_set = "default")))

    asserts.equals(env, {"cpu": 2}, _call_resource_set("cpu_2"))
    asserts.equals(env, {"cpu": 4}, _call_resource_set("cpu_4"))
    asserts.equals(env, {"memory": 8192}, _call_resource_set("mem_8g"))

    asserts.equals(env, None, resource_set_for(cpu_cores = 0, mem_mb = 0))
    asserts.equals(env, {"cpu": 42}, resource_set_for(cpu_cores = 42, mem_mb = 0)("", ""))
    asserts.equals(env, {"cpu": 64}, resource_set_for(cpu_cores = 100, mem_mb = 0)("", ""))

    asserts.equals(env, {"memory": 512}, resource_set_for(cpu_cores = 0, mem_mb = 10)("", ""))
    asserts.equals(env, {"memory": 1024}, resource_set_for(cpu_cores = 0, mem_mb = 600)("", ""))
    asserts.equals(env, {"memory": 32768}, resource_set_for(cpu_cores = 0, mem_mb = 600000000)("", ""))

    asserts.equals(env, {"cpu": 42, "memory": 512}, resource_set_for(cpu_cores = 42, mem_mb = 10)("", ""))

    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
t0_test = unittest.make(_resource_set_test_impl)

def resource_sets_test_suite():
    unittest.suite("resource_sets_tests", partial.make(t0_test, timeout = "short"))
