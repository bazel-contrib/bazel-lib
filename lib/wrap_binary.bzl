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

def tty_binary(name, binary, runfiles_manifest_key, **kwargs):
    """Wrap a binary such that it sees a tty attached to its stdin

    Args:
        name: Name of the rule
        binary: Label of an executable target to wrap
        runfiles_manifest_key: WORKAROUND: a lookup into the runfiles manifest for the binary
        **kwargs: Additional named arguments for the resulting sh_binary rule.
    """

    script = "_{}_w_tty.sh".format(name)
    binary = to_label(binary)

    write_file(
        name = "_{}_wrap".format(name),
        out = script,
        content = [
            "#!/usr/bin/env bash",
            BASH_RLOCATION_FUNCTION,
            # Remove external/ prefix that is included in $(rootpath) but not supported by $(rlocation)
            #"bin=$(rlocation ${1#external/})",
            "bin=$(rlocation {})".format(runfiles_manifest_key),

            # Replace the current process with socat
            # Based on https://unix.stackexchange.com/questions/157458/make-program-in-a-pipe-think-it-has-tty
            #
            # Explanation of options:
            # pty: Establishes communication with the sub process using a pseudo terminal instead of a socket pair.
            #      Creates the pty with an available mechanism.
            #      If openpty and ptmx are both available, it uses ptmx because this is POSIX compliant
            # setsid: Makes the process the leader of a new session
            # ctty: Makes the pty the controlling tty of the sub process
            "exec socat - EXEC:\"$bin $@\",pty,setsid,ctty",
        ],
        is_executable = True,
    )

    native.sh_binary(
        name = name,
        srcs = [script],
        #args = ["$(rootpath {})".format(binary)] + kwargs.pop("args", []),
        data = [binary],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        **kwargs
    )
