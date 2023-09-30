"""General-purpose rule to create tar archives.

Unlike [pkg_tar from rules_pkg](https://github.com/bazelbuild/rules_pkg/blob/main/docs/latest.md#pkg_tar)
this:

- Does not depend on any Python interpreter setup
- Does not have any custom program to produce the output, instead
  we rely on a well-known C++ program called "tar".
  Specifically, we use the BSD variant of tar since it provides a means
  of controlling mtimes, uid, symlinks, etc.

We also provide full control for tar'ring binaries including their runfiles.
"""

load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib/private:tar.bzl", _tar_lib = "tar_lib")

tar_rule = rule(
    doc = "Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.",
    implementation = _tar_lib.implementation,
    attrs = _tar_lib.attrs,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
)

def tar(name, mtree = None, **kwargs):
    """Wrapper macro around [`tar_rule`](#tar_rule).

    Allows the mtree to be supplied as an array literal of lines, in addition to a separate file, e.g.

    ```
    mtree =[
        "usr/bin uid=0 gid=0 mode=0755 type=dir",
        "usr/bin/ls uid=0 gid=0 mode=0755 time=0 type=file content={}/a".format(package_name()),
    ],
    ```

    For the format of a line, see "There are four types of lines in a specification" on the man page for BSD mtree,
    https://man.freebsd.org/cgi/man.cgi?mtree(8)

    Args:
        name: name of resulting `tar_rule`
        mtree: either an array of specification lines, or a label of a file that contains the lines.
        **kwargs: additional named parameters to pass to `tar_rule`
    """
    if types.is_list(mtree):
        write_target = "_{}.mtree".format(name)
        write_file(
            name = write_target,
            out = "{}.txt".format(write_target),
            # Ensure there's a trailing newline, as bsdtar will ignore a last line without one
            content = mtree + [""],
        )
        mtree = write_target

    tar_rule(
        name = name,
        mtree = mtree,
        **kwargs
    )
