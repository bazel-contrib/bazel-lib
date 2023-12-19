"bats_test"

load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION", "to_rlocation_path")

_RUNNER_TMPL = """#!/usr/bin/env bash

{BASH_RLOCATION_FUNCTION}

# set -o errexit -o nounset -o pipefail

readonly core_path="$(rlocation {core})"
readonly bats="$core_path/bin/bats"
readonly libs=( {libraries} )

{envs}

NEW_LIBS=()
for lib in "${{libs[@]}}"; do
    NEW_LIBS+=( $(cd "$(rlocation $lib)/.." && pwd) )
done

export BATS_LIB_PATH=$(
    IFS=:
    echo "${{NEW_LIBS[*]}}"
)
export BATS_TEST_TIMEOUT="$TEST_TIMEOUT"
export BATS_TMPDIR="$TEST_TMPDIR"

exec $bats {tests} $@
"""

_ENV_SET = """export {var}=\"{value}\""""

def _bats_test_impl(ctx):
    toolchain = ctx.toolchains["@aspect_bazel_lib//lib:bats_toolchain_type"]
    batsinfo = toolchain.batsinfo

    envs = []
    for (key, value) in ctx.attr.env.items():
        envs.append(_ENV_SET.format(
            var = key,
            value = " ".join([expand_variables(ctx, exp, attribute_name = "env") for exp in expand_locations(ctx, value, ctx.attr.data).split(" ")]),
        ))

    runner = ctx.actions.declare_file("%s_bats.sh" % ctx.label.name)
    ctx.actions.write(
        output = runner,
        content = _RUNNER_TMPL.format(
            core = to_rlocation_path(ctx, batsinfo.core),
            libraries = " ".join([to_rlocation_path(ctx, lib) for lib in batsinfo.libraries]),
            tests = " ".join([test.short_path for test in ctx.files.srcs]),
            envs = "\n".join(envs),
            BASH_RLOCATION_FUNCTION = BASH_RLOCATION_FUNCTION,
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(ctx.files.srcs + ctx.files.data)
    runfiles = runfiles.merge(toolchain.default.default_runfiles)
    runfiles = runfiles.merge(ctx.attr._runfiles.default_runfiles)

    return DefaultInfo(
        executable = runner,
        runfiles = runfiles,
    )

bats_test = rule(
    implementation = _bats_test_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".bats"],
            doc = "Test files",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Runtime dependencies of the test.",
        ),
        "env": attr.string_dict(
            doc = """Environment variables of the action.

            Subject to [$(location)](https://bazel.build/reference/be/make-variables#predefined_label_variables)
            and ["Make variable"](https://bazel.build/reference/be/make-variables) substitution.
            """,
        ),
        "_runfiles": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
    },
    toolchains = ["@aspect_bazel_lib//lib:bats_toolchain_type"],
    test = True,
)
