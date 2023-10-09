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

# LOCAL MODIFICATIONS
# this has a PR patched in on top of the original
# https://github.com/bazelbuild/bazel-skylib/blob/7b859037a673db6f606661323e74c5d4751595e6/rules/private/copy_file_private.bzl
# https://github.com/bazelbuild/bazel-skylib/pull/324

"""Implementation of copy_file macro and underlying rules.

These rules copy a file to another location using Bash (on Linux/macOS) or
cmd.exe (on Windows). `_copy_xfile` marks the resulting file executable,
`_copy_file` does not.
"""

load(":copy_common.bzl", "execution_requirements_for_copy", _progress_path = "progress_path")
load(":directory_path.bzl", "DirectoryPathInfo")
load(":platform_utils.bzl", _platform_utils = "platform_utils")

def _copy_cmd(ctx, src, src_path, dst, override_execution_requirements = None):
    # Most Windows binaries built with MSVC use a certain argument quoting
    # scheme. Bazel uses that scheme too to quote arguments. However,
    # cmd.exe uses different semantics, so Bazel's quoting is wrong here.
    # To fix that we write the command to a .bat file so no command line
    # quoting or escaping is required.
    # Put a hash of the file name into the name of the generated batch file to
    # make it unique within the package, so that users can define multiple copy_file's.
    # The label of the target is intentionally not included so that two different targets
    # can copy the same file to the output tree.
    bat = ctx.actions.declare_file("%s-cmd.bat" % hash(src_path + dst.short_path))

    # Flags are documented at
    # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/copy
    cmd_tmpl = "@copy /Y \"{src}\" \"{dst}\" >NUL"
    mnemonic = "CopyFile"
    progress_message = "Copying file %s" % _progress_path(src)

    ctx.actions.write(
        output = bat,
        # Do not use lib/shell.bzl's shell.quote() method, because that uses
        # Bash quoting syntax, which is different from cmd.exe's syntax.
        content = cmd_tmpl.format(
            src = src_path.replace("/", "\\"),
            dst = dst.path.replace("/", "\\"),
        ),
        is_executable = True,
    )
    ctx.actions.run(
        inputs = [src],
        tools = [bat],
        outputs = [dst],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = mnemonic,
        progress_message = progress_message,
        use_default_shell_env = True,
        execution_requirements = override_execution_requirements or execution_requirements_for_copy(ctx),
    )

def _copy_bash(ctx, src, src_path, dst, override_execution_requirements = None):
    cmd_tmpl = "cp -f \"$1\" \"$2\""
    mnemonic = "CopyFile"
    progress_message = "Copying file %s" % _progress_path(src)

    ctx.actions.run_shell(
        tools = [src],
        outputs = [dst],
        command = cmd_tmpl,
        arguments = [src_path, dst.path],
        mnemonic = mnemonic,
        progress_message = progress_message,
        use_default_shell_env = True,
        execution_requirements = override_execution_requirements or execution_requirements_for_copy(ctx),
    )

def copy_file_action(ctx, src, dst, dir_path = None, is_windows = None):
    """Factory function that creates an action to copy a file from src to dst.

    If src is a TreeArtifact, dir_path must be specified as the path within
    the TreeArtifact to the file to copy.

    This helper is used by copy_file. It is exposed as a public API so it can be used within
    other rule implementations.

    Args:
        ctx: The rule context.
        src: The source file to copy or TreeArtifact to copy a single file out of.
        dst: The destination file.
        dir_path: If src is a TreeArtifact, the path within the TreeArtifact to the file to copy.
        is_windows: Deprecated and unused
    """

    # TODO(2.0): remove deprecated & unused is_windows parameter
    if dst.is_directory:
        fail("dst must not be a TreeArtifact")
    if src.is_directory:
        if not dir_path:
            fail("dir_path must be set if src is a TreeArtifact")
        src_path = "/".join([src.path, dir_path])
    else:
        src_path = src.path

    # Because copy actions have "local" execution requirements, we can safely assume
    # the execution is the same as the host platform and generate different actions for Windows
    # and non-Windows host platforms
    is_windows = _platform_utils.host_platform_is_windows()
    if is_windows:
        _copy_cmd(ctx, src, src_path, dst)
    else:
        _copy_bash(ctx, src, src_path, dst)

def _copy_file_impl(ctx):
    if ctx.attr.allow_symlink:
        if len(ctx.files.src) != 1:
            fail("src must be a single file when allow_symlink is True")
        if ctx.files.src[0].is_directory:
            fail("cannot use copy_file to create a symlink to a directory")
        ctx.actions.symlink(
            output = ctx.outputs.out,
            target_file = ctx.files.src[0],
            is_executable = ctx.attr.is_executable,
        )
    elif DirectoryPathInfo in ctx.attr.src:
        copy_file_action(
            ctx,
            ctx.attr.src[DirectoryPathInfo].directory,
            ctx.outputs.out,
            dir_path = ctx.attr.src[DirectoryPathInfo].path,
        )
    else:
        if len(ctx.files.src) != 1:
            fail("src must be a single file or a target that provides a DirectoryPathInfo")
        if ctx.files.src[0].is_directory:
            fail("cannot use copy_file on a directory; try copy_directory instead")
        copy_file_action(ctx, ctx.files.src[0], ctx.outputs.out)

    files = depset(direct = [ctx.outputs.out])
    runfiles = ctx.runfiles(files = [ctx.outputs.out])
    if ctx.attr.is_executable:
        return [DefaultInfo(files = files, runfiles = runfiles, executable = ctx.outputs.out)]
    else:
        return [DefaultInfo(files = files, runfiles = runfiles)]

_ATTRS = {
    "src": attr.label(mandatory = True, allow_files = True),
    "is_executable": attr.bool(mandatory = True),
    "allow_symlink": attr.bool(mandatory = True),
    "out": attr.output(mandatory = True),
    "_options": attr.label(default = "//lib:copy_options"),
}

_copy_file = rule(
    implementation = _copy_file_impl,
    provides = [DefaultInfo],
    attrs = _ATTRS,
)

_copy_xfile = rule(
    implementation = _copy_file_impl,
    executable = True,
    provides = [DefaultInfo],
    attrs = _ATTRS,
)

def copy_file(name, src, out, is_executable = False, allow_symlink = False, **kwargs):
    """Copies a file or directory to another location.

    `native.genrule()` is sometimes used to copy files (often wishing to rename them). The 'copy_file' rule does this with a simpler interface than genrule.

    This rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command on Windows (no Bash is required).

    If using this rule with source directories, it is recommended that you use the
    `--host_jvm_args=-DBAZEL_TRACK_SOURCE_DIRECTORIES=1` startup option so that changes
    to files within source directories are detected. See
    https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
    for more context.

    Args:
      name: Name of the rule.
      src: A Label. The file to make a copy of.
          (Can also be the label of a rule that generates a file.)
      out: Path of the output file, relative to this package.
      is_executable: A boolean. Whether to make the output file executable. When
          True, the rule's output can be executed using `bazel run` and can be
          in the srcs of binary and test rules that require executable sources.
          WARNING: If `allow_symlink` is True, `src` must also be executable.
      allow_symlink: A boolean. Whether to allow symlinking instead of copying.
          When False, the output is always a hard copy. When True, the output
          *can* be a symlink, but there is no guarantee that a symlink is
          created (i.e., at the time of writing, we don't create symlinks on
          Windows). Set this to True if you need fast copying and your tools can
          handle symlinks (which most UNIX tools can).
      **kwargs: further keyword arguments, e.g. `visibility`
    """

    copy_file_impl = _copy_file
    if is_executable:
        copy_file_impl = _copy_xfile

    copy_file_impl(
        name = name,
        src = src,
        out = out,
        is_executable = is_executable,
        allow_symlink = allow_symlink,
        **kwargs
    )
