"""Implementation of copy_directory macro and underlying rules.

This rule copies a directory to another location using Bash (on Linux/macOS) or
cmd.exe (on Windows).
"""

# Hints for Bazel spawn strategy
_execution_requirements = {
    # Copying files is entirely IO-bound and there is no point doing this work remotely.
    # Also, remote-execution does not allow source directory inputs, see
    # https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
    # So we must not attempt to execute remotely in that case.
    "no-remote-exec": "1",
}

# buildifier: disable=function-docstring
def copy_cmd(ctx, src_dir, src_path, dst):
    # Most Windows binaries built with MSVC use a certain argument quoting
    # scheme. Bazel uses that scheme too to quote arguments. However,
    # cmd.exe uses different semantics, so Bazel's quoting is wrong here.
    # To fix that we write the command to a .bat file so no command line
    # quoting or escaping is required.
    # Put a hash of the file name into the name of the generated batch file to
    # make it unique within the package, so that users can define multiple copy_file's.
    bat = ctx.actions.declare_file("%s-%s-cmd.bat" % (ctx.label.name, hash(src_path)))

    # Flags are documented at
    # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy
    # NB: robocopy return non-zero exit codes on success so we must exit 0 after calling it
    cmd_tmpl = "@robocopy \"{src}\" \"{dst}\" /E >NUL & @exit 0"
    mnemonic = "CopyDirectory"
    progress_message = "Copying directory %s" % src_path

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
        inputs = [src_dir],
        tools = [bat],
        outputs = [dst],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = mnemonic,
        progress_message = progress_message,
        use_default_shell_env = True,
        execution_requirements = _execution_requirements,
    )

# buildifier: disable=function-docstring
def copy_bash(ctx, src_dir, src_path, dst):
    cmd_tmpl = "rm -rf \"$2\" && cp -fR \"$1/\" \"$2\""
    mnemonic = "CopyDirectory"
    progress_message = "Copying directory %s" % src_path

    ctx.actions.run_shell(
        tools = [src_dir],
        outputs = [dst],
        command = cmd_tmpl,
        arguments = [src_path, dst.path],
        mnemonic = mnemonic,
        progress_message = progress_message,
        use_default_shell_env = True,
        execution_requirements = _execution_requirements,
    )

def _copy_directory_impl(ctx):
    output = ctx.actions.declare_directory(ctx.attr.out)
    src_dir = ctx.file.src
    src_path = src_dir.path
    if ctx.attr.is_windows:
        copy_cmd(ctx, src_dir, src_path, output)
    else:
        copy_bash(ctx, src_dir, src_path, output)

    files = depset(direct = [output])
    runfiles = ctx.runfiles(files = [output])

    return [DefaultInfo(files = files, runfiles = runfiles)]

_copy_directory = rule(
    implementation = _copy_directory_impl,
    provides = [DefaultInfo],
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "is_windows": attr.bool(mandatory = True),
        # Cannot declare out as an output here, because there's no API for declaring
        # TreeArtifact outputs.
        "out": attr.string(mandatory = True),
    },
)

def copy_directory(name, src, out, **kwargs):
    """Copies a directory to another location.

    This rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command on Windows (no Bash is required).

    If using this rule with source directories, it is recommended that you use the
    `--host_jvm_args=-DBAZEL_TRACK_SOURCE_DIRECTORIES=1` startup option so that changes
    to files within source directories are detected. See
    https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
    for more context.

    Args:
      name: Name of the rule.
      src: A Label. The directory to make a copy of.
          (Can also be the label of a rule that generates a directory.)
      out: Path of the output directory, relative to this package.
      **kwargs: further keyword arguments, e.g. `visibility`
    """
    _copy_directory(
        name = name,
        src = src,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        out = out,
        **kwargs
    )
