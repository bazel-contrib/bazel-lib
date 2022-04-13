# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Implementation of copy_to_bin macro and underlying rules."""

load(":copy_file.bzl", "copy_file_action")

def copy_to_bin_action(ctx, files, is_windows = False):
    """Helper function that creates actions to copy files to the output tree.

    Files are copied to the same workspace-relative path. The resulting list of
    files is returned.

    If a file passed in is already in the output tree is then it is added
    directly to the result without a copy action.

    Args:
        ctx: The rule context.
        files: List of File objects.
        is_windows: If true, an cmd.exe action is created so there is no bash dependency.

    Returns:
        List of File objects in the output tree.
    """
    result = []
    for src in files:
        if not src.is_source:
            result.append(src)
            continue
        dst = ctx.actions.declare_file(src.basename, sibling = src)
        copy_file_action(ctx, src, dst, is_windows = is_windows)
        result.append(dst)
    return result

def _impl(ctx):
    files = copy_to_bin_action(ctx, ctx.files.srcs, is_windows = ctx.attr.is_windows)
    return DefaultInfo(
        files = depset(files),
        runfiles = ctx.runfiles(files = files),
    )

_copy_to_bin = rule(
    implementation = _impl,
    provides = [DefaultInfo],
    attrs = {
        "is_windows": attr.bool(mandatory = True),
        "srcs": attr.label_list(mandatory = True, allow_files = True),
    },
)

def copy_to_bin(name, srcs, **kwargs):
    """Copies a source file to output tree at the same workspace-relative path.

    e.g. `<execroot>/path/to/file -> <execroot>/bazel-out/<platform>/bin/path/to/file`

    If a file passed in is already in the output tree is then it is added directly to the
    DefaultInfo provided by the rule without a copy.

    This is useful to populate the output folder with all files needed at runtime, even
    those which aren't outputs of a Bazel rule.

    This way you can run a binary in the output folder (execroot or runfiles_root)
    without that program needing to rely on a runfiles helper library or be aware that
    files are divided between the source tree and the output tree.

    Args:
        name: Name of the rule.
        srcs: A list of labels. File(s) to copy.
        **kwargs: further keyword arguments, e.g. `visibility`
    """
    _copy_to_bin(
        name = name,
        srcs = srcs,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
