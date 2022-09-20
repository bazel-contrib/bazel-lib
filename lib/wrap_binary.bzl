"""Wraps binary rules to make them more compatible with Bazel.

Currently supports only Bash as the wrapper language, not cmd.exe.

Future additions might include:
- wrap a binary such that it sees a tty on stdin
- manipulate arguments or environment variables
- redirect stdout/stderr, e.g. to silence buildspam on success
- intercept exit code, e.g. to make an "expect_fail"
- change user, e.g. to deal with containerized build running as root, but tool requires non-root
- intercept signals, e.g. to make a tool behave as a Bazel persistent worker
"""

load(":paths.bzl", "BASH_RLOCATION_FUNCTION")
load(":utils.bzl", "to_label")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def chdir_binary(name, binary, chdir = "$BUILD_WORKSPACE_DIRECTORY", **kwargs):
    """Wrap a *_binary to be executed under a given working directory.

    Note: under `bazel run`, this is similar to the `--run_under "cd $PWD &&"` trick, but is hidden
    from the user so they don't need to know about that flag.

    Args:
        name: Name of the rule.
        binary: Label of an executable target to wrap.
        chdir: Argument for the `cd` command.
            By default, supports using the binary under `bazel run` by running program in the
            root of the Bazel workspace, in the source tree.
        **kwargs: Additional named arguments for the resulting sh_binary rule.
    """

    script = "_{}_chdir.sh".format(name)
    binary = to_label(binary)

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
