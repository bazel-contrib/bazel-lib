"Public API"

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib/private:paths.bzl", "paths")

relative_file = paths.relative_file
to_manifest_path = paths.to_manifest_path
to_workspace_path = paths.to_workspace_path
to_output_relative_path = paths.to_output_relative_path

# Bash helper function for looking up runfiles.
# See windows_utils.bzl for the cmd.exe equivalent.
# Vendored from
# https://github.com/bazelbuild/bazel/blob/master/tools/bash/runfiles/runfiles.bash
BASH_RLOCATION_FUNCTION = r"""
# --- begin runfiles.bash initialization v2 ---
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---
"""

def chdir_binary(name, binary, chdir = "$BUILD_WORKSPACE_DIRECTORY", **kwargs):
    """Wrap a *_binary to be executed under a given directory.

    Args:
        name: Name of the rule.
        binary: Label of an executable target to wrap.
        chdir: Argument for the `cd` command, the default is commonly used with `bazel run`
            to run the program in the root of the Bazel workspace, in the source tree.
        **kwargs: Additional named arguments for the resulting sh_binary rule.
    """

    script = "_{}_chdir.sh".format(name)

    # It's 2022 and java_binary still cannot be told to cd to the source directory under bazel run.
    write_file(
        name = "_{}_wrap".format(name),
        out = script,
        content = [
            "#!/usr/bin/env bash",
            BASH_RLOCATION_FUNCTION,
            # Remove external/ prefix that is included in $(rootpath) but not supported by $(rlocation)
            "bin=$(rlocation ${1#external/})",
            # Consume the first argument
            "shift",
            # Fix the working directory
            "cd " + chdir,
            # Replace the current process
            "exec $bin $@",
        ],
        is_executable = True,
    )

    native.sh_binary(
        name = name,
        srcs = [script],
        args = ["$(rootpath {})".format(binary)] + kwargs.pop("args", []),
        data = [binary],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        **kwargs
    )
