#!/usr/bin/env python3

# to regenerate, run this as
# lib/private/resource_sets_generator.py | buildifier - > lib/private/resource_sets.bzl

from pprint import pformat

# Configuration goes here!
CPU_COUNT: int = 64
MEMORY_SIZES: list[int] = [
    0,
    512,
    1024,
    2048,
    4096,
    8192,
    16384,
    32768,
]


def cpu_dict(cpu: int) -> dict[str, int]:
    if cpu == 0:
        return {}
    else:
        return {"cpu": cpu}


def mem_dict(mem: int) -> dict[str, int]:
    if mem == 0:
        return {}
    else:
        return {"memory": mem}


def resource_func(cpu: int, mem: int) -> str:
    name = f"_resource_set_cpu_{cpu}_mem_{mem}"
    value = cpu_dict(cpu) | mem_dict(mem)

    print(f"def {name}(_, __):")
    print(f"    return {value}")
    print()
    return name


def main() -> None:
    resource_sets: dict[int, dict[int, str]] = {}

    print('"""generated with lib/private/resource_sets_generator.py | buildifier - > lib/private/resource_sets.bzl"""')
    print()

    for cpu in range(CPU_COUNT + 1):
        for mem in MEMORY_SIZES:
            # Don't bother to generate the degenerate case; we return a None
            # here
            if cpu == 0 and mem == 0:
                continue

            name = resource_func(cpu, mem)
            resource_sets.setdefault(cpu, {})[mem] = name

    # This will be formatted wrong, but formatted wrong in a way that
    # buildifier knows how to correct :)
    print(f"_RESOURCE_SETS = {pformat(resource_sets).replace('\'', '')}")
    print()
    print(f"_MEMORY_SIZES = {pformat(MEMORY_SIZES)}")

    print(
        f"""
# buildifier: disable=function-docstring
def resource_lookup(cpu, mem):
    if cpu == 0 and mem == 0:
        return None

    if cpu < 0:
        fail("cpu must be >= 0, not", cpu)
    elif cpu > {CPU_COUNT}:
        cpu = {CPU_COUNT}

    if mem < 0:
        fail("mem must be >= 0, not", mem)
    elif mem >= {MEMORY_SIZES[-1]}:
        mem = {MEMORY_SIZES[-1]}
    else:
        for i in _MEMORY_SIZES:
            if i >= mem:
                mem = i
                break

    return _RESOURCE_SETS[cpu][mem]
"""
    )


if __name__ == "__main__":
    main()
