"""Utilities for rules that expose resource_set on ctx.actions.run[_shell]

Workaround for https://github.com/bazelbuild/bazel/issues/15187

Note, this workaround only provides some fixed values for either CPU or Memory.

Rule authors who are ALSO the BUILD author might know better, and can
write custom resource_set functions for use within their own repository.
This seems to be the use case that Google engineers imagined.
"""

load(
    "//lib/private:resource_sets.bzl",
    _resource_lookup = "resource_lookup",
)

resource_set_values = [
    "cpu_2",
    "cpu_4",
    "default",
    "mem_512m",
    "mem_1g",
    "mem_2g",
    "mem_4g",
    "mem_8g",
    "mem_16g",
    "mem_32g",
]

# buildifier: disable=function-docstring
def resource_set(attr):
    cpu = 0
    mem = 0

    if attr.resource_set == "cpu_2":
        cpu = 2
    elif attr.resource_set == "cpu_4":
        cpu = 4
    elif attr.resource_set == "default":
        return None
    elif attr.resource_set == "mem_512m":
        mem = 512
    elif attr.resource_set == "mem_1g":
        mem = 1024
    elif attr.resource_set == "mem_2g":
        mem = 2048
    elif attr.resource_set == "mem_4g":
        mem = 4096
    elif attr.resource_set == "mem_8g":
        mem = 8192
    elif attr.resource_set == "mem_16g":
        mem = 16384
    elif attr.resource_set == "mem_32g":
        mem = 32768
    else:
        fail("unknown resource set", attr.resource_set)

    return _resource_lookup(cpu, mem)

def resource_set_for(*, cpu_cores = 0, mem_mb = 0):
    """ return an appropriate resource_set for the given values.

    Args:
        cpu_cores: (int) the number of cores to request. 0 means "use the bazel
                   default". If the value is larger than the hard-coded max value, it will
                   be clamped to the max value.

        mem_mb: (int) megabytes of memory to request. 0 means "use the bazel
                default". The value will be rounded up to a supported ram value, and
                will be clamped to the max value.

    Returns:
        a resource_set function, as required by `ctx.actions.run` and `ctx.actions.run_shell`
"""
    return _resource_lookup(cpu_cores, mem_mb)

resource_set_attr = {
    "resource_set": attr.string(
        doc = """A predefined function used as the resource_set for actions.

        Used with --experimental_action_resource_set to reserve more RAM/CPU, preventing Bazel overscheduling resource-intensive actions.

        By default, Bazel allocates 1 CPU and 250M of RAM.
        https://github.com/bazelbuild/bazel/blob/058f943037e21710837eda9ca2f85b5f8538c8c5/src/main/java/com/google/devtools/build/lib/actions/AbstractAction.java#L77
        """,
        default = "default",
        values = resource_set_values,
    ),
}
