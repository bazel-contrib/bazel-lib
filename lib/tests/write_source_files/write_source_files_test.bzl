"""Tests for write_source_files"""
# Inspired by https://github.com/cgrindel/bazel-starlib/blob/main/updatesrc/private/updatesrc_update_test.bzl

load("//lib/private:write_source_files.bzl", _lib = "write_source_files_lib")

_write_source_files = rule(
    attrs = _lib.attrs,
    implementation = _lib.implementation,
    executable = True,
)

def _impl(ctx):
    test = ctx.actions.declare_file(
        ctx.label.name + "_test.sh",
    )

    ctx.actions.write(
        output = test,
        is_executable = True,
        content = """
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

assert_different() {
  local in_file="${1}"
  local out_file="${2}"
  diff  "${in_file}" "${out_file}" > /dev/null && (echo >&2 "Expected files to differ. in: ${in_file}, out: ${out_file}" && return -1)
  return 0
}

assert_same() {
  local in_file="${1}"
  local out_file="${2}"
  diff  "${in_file}" "${out_file}" || (echo >&2 "Expected files to be same. in: ${in_file}, out: ${out_file}" && return -1)
}

# Check that in and out files are different
""" + "\n".join([
            "assert_different {in_file} {out_file}".format(
                in_file = ctx.files.in_files[i].short_path,
                out_file = ctx.files.out_files[i].short_path,
            )
            for i in range(len(ctx.files.in_files))
        ]) + """
# Write to the source files
{write_source_files}

# Check that in and out files are the same
""".format(write_source_files = ctx.file.write_source_files_target.short_path) + "\n".join([
            "assert_same {in_file} {out_file}".format(
                in_file = ctx.files.in_files[i].short_path,
                out_file = ctx.files.out_files[i].short_path,
            )
            for i in range(len(ctx.files.in_files))
        ]),
    )

    return DefaultInfo(
        executable = test,
        runfiles = ctx.runfiles(files = [ctx.file.write_source_files_target] + ctx.files.in_files + ctx.files.out_files),
    )

_write_source_files_test = rule(
    implementation = _impl,
    attrs = {
        "write_source_files_target": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "out_files": attr.label_list(
            allow_files = True,
            allow_empty = False,
            mandatory = True,
        ),
        "in_files": attr.label_list(
            allow_files = True,
            allow_empty = False,
            mandatory = True,
        ),
    },
    test = True,
)

def write_source_files_test(name, in_files, out_files):
    """Stamp a write_source_files executable and a test to run against it"""

    _write_source_files(
        name = name + "_updater",
        out_files = out_files,
        in_files = in_files,
        is_windows = False,
    )

    # Note that for testing we update the source files in the sandbox,
    # not the actual source tree.
    _write_source_files_test(
        name = name,
        write_source_files_target = name + "_updater",
        out_files = out_files,
        in_files = in_files,
    )
