"write_source_file implementation"

load(":directory_path.bzl", "DirectoryPathInfo")
load(":diff_test.bzl", _diff_test = "diff_test")
load(":fail_with_message_test.bzl", "fail_with_message_test")
load(":utils.bzl", "utils")

WriteSourceFileInfo = provider(
    "Provider for write_source_file targets",
    fields = {
        "executable": "Executable that updates the source files",
    },
)

def write_source_file(
        name,
        in_file = None,
        out_file = None,
        additional_update_targets = [],
        suggested_update_target = None,
        diff_test = True,
        **kwargs):
    """Write a file or folder to the output tree. Stamp out tests that ensure the sources exist and are up to date.

    Args:
        name: Name of the executable target that creates or updates the source file
        in_file: File to use as the desired content to write to out_file. If in_file is a TreeArtifact then entire directory contents are copied.
        out_file: The file to write to in the source tree. Must be within the same bazel package as the target.
        additional_update_targets: List of other write_source_file or other executable updater targets to call in the same run
        suggested_update_target: Label of the write_source_file target to suggest running when files are out of date
        diff_test: Generate a test target to check that the source file(s) exist and are up to date with the generated files(s).
        **kwargs: Other common named parameters such as `tags` or `visibility`
    """
    if out_file:
        if not in_file:
            fail("in_file must be specified if out_file is set")

    if in_file:
        if not out_file:
            fail("out_file must be specified if in_file is set")

    if in_file and out_file:
        in_file = utils.to_label(in_file)
        out_file = utils.to_label(out_file)

        if utils.is_external_label(out_file):
            msg = "out file {} must be in the user workspace".format(out_file)
            fail(msg)
        if out_file.package != native.package_name():
            msg = "out file {} (in package '{}') must be a source file within the target's package: '{}'".format(out_file, out_file.package, native.package_name())
            fail(msg)

    _write_source_file(
        name = name,
        in_file = in_file,
        out_file = out_file.name if out_file else None,
        additional_update_targets = additional_update_targets,
        **kwargs
    )

    if not in_file or not out_file or not diff_test:
        return

    out_file_missing = _is_file_missing(out_file)
    test_target_name = "%s_test" % name

    if out_file_missing:
        if suggested_update_target == None:
            message = """

%s does not exist. To create & update this file, run:

    bazel run //%s:%s

""" % (out_file, native.package_name(), name)
        else:
            message = """

%s does not exist. To create & update this and other generated files, run:

    bazel run %s

To create an update *only* this file, run:

    bazel run //%s:%s

""" % (out_file, utils.to_label(suggested_update_target), native.package_name(), name)

        # Stamp out a test that fails with a helpful message when the source file doesn't exist.
        # Note that we cannot simply call fail() here since it will fail during the analysis
        # phase and prevent the user from calling bazel run //update/the:file.
        fail_with_message_test(
            name = test_target_name,
            message = message,
            visibility = kwargs.get("visibility"),
            tags = kwargs.get("tags"),
        )
    else:
        if suggested_update_target == None:
            message = """

%s is out of date. To update this file, run:

    bazel run //%s:%s

""" % (out_file, native.package_name(), name)
        else:
            message = """

%s is out of date. To update this and other generated files, run:

    bazel run %s

To update *only* this file, run:

    bazel run //%s:%s

""" % (out_file, utils.to_label(suggested_update_target), native.package_name(), name)

        # Stamp out a diff test the check that the source file is up to date
        _diff_test(
            name = test_target_name,
            file1 = in_file,
            file2 = out_file,
            failure_message = message,
            **kwargs
        )

_write_source_file_attrs = {
    "in_file": attr.label(allow_files = True, mandatory = False),
    # out_file is intentionally an attr.string() and not a attr.label(). This is so that
    # bazel query 'kind("source file", deps(//path/to:target))' does not return
    # out_file in the list of source file deps. ibazel uses this query to determine
    # which source files to watch so if the out_file is returned then ibazel watches
    # and it goes into an infinite update, notify loop when running this target.
    # See https://github.com/aspect-build/bazel-lib/pull/52 for more context.
    "out_file": attr.string(mandatory = False),
    # buildifier: disable=attr-cfg
    "additional_update_targets": attr.label_list(cfg = "host", mandatory = False, providers = [WriteSourceFileInfo]),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _write_source_file_sh(ctx, paths):
    updater = ctx.actions.declare_file(
        ctx.label.name + "_update.sh",
    )

    additional_update_scripts = []
    for target in ctx.attr.additional_update_targets:
        additional_update_scripts.append(target[WriteSourceFileInfo].executable)

    contents = ["""#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
runfiles_dir=$PWD
# BUILD_WORKSPACE_DIRECTORY not set when running as a test, uses the sandbox instead
if [[ ! -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
    cd "$BUILD_WORKSPACE_DIRECTORY"
fi"""]

    for in_path, out_path in paths:
        contents.append("""
in=$runfiles_dir/{in_path}
out={out_path}

mkdir -p "$(dirname "$out")"
echo "Copying $in to $out in $PWD"

if [[ -f "$in" ]]; then
    cp -f "$in" "$out"
    chmod ug+w "$out"
else
    rm -Rf "$out"/*
    mkdir -p "$out"
    cp -fRL "$in"/* "$out"
    chmod -R ug+w "$out"/*
fi
""".format(in_path = in_path, out_path = out_path))

    contents.extend([
        "cd \"$runfiles_dir\"",
        "# Run the update scripts for all write_source_file deps",
    ])
    for update_script in additional_update_scripts:
        contents.append("./\"{update_script}\"".format(update_script = update_script.short_path))

    ctx.actions.write(
        output = updater,
        is_executable = True,
        content = "\n".join(contents),
    )

    return updater

def _write_source_file_bat(ctx, paths):
    updater = ctx.actions.declare_file(
        ctx.label.name + "_update.bat",
    )

    additional_update_scripts = []
    for target in ctx.attr.additional_update_targets:
        if target[DefaultInfo].files_to_run and target[DefaultInfo].files_to_run.executable:
            additional_update_scripts.append(target[DefaultInfo].files_to_run.executable)
        else:
            fail("additional_update_targets target %s does not provide an executable")

    contents = ["""@rem @generated by @aspect_bazel_lib//:lib/private:write_source_file.bzl
@echo off
set runfiles_dir=%cd%
if defined BUILD_WORKSPACE_DIRECTORY (
    cd %BUILD_WORKSPACE_DIRECTORY%
)"""]

    for in_path, out_path in paths:
        contents.append("""
set in=%runfiles_dir%\\{in_path}
set out={out_path}

if not defined BUILD_WORKSPACE_DIRECTORY (
    @rem Because there's no sandboxing in windows, if we copy over the target
    @rem file's symlink it will get copied back into the source directory
    @rem during tests. Work around this in tests by deleting the target file
    @rem symlink before copying over it.
    del %out%
)

echo Copying %in% to %out% in %cd%

if exist "%in%\\*" (
    mkdir "%out%" >NUL 2>NUL
    robocopy "%in%" "%out%" /E >NUL
) else (
    copy %in% %out% >NUL
)
""".format(in_path = in_path.replace("/", "\\"), out_path = out_path.replace("/", "\\")))

    contents.extend([
        "cd %runfiles_dir%",
        "@rem Run the update scripts for all write_source_file deps",
    ])
    for update_script in additional_update_scripts:
        contents.append("call {update_script}".format(update_script = update_script.short_path))

    ctx.actions.write(
        output = updater,
        is_executable = True,
        content = "\n".join(contents).replace("\n", "\r\n"),
    )
    return updater

def _write_source_file_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if ctx.attr.out_file and not ctx.attr.in_file:
        fail("in_file must be specified if out_file is set")
    if ctx.attr.in_file and not ctx.attr.out_file:
        fail("out_file must be specified if in_file is set")

    paths = []
    runfiles = []

    if ctx.attr.in_file and ctx.attr.out_file:
        if DirectoryPathInfo in ctx.attr.in_file:
            in_path = "/".join([
                ctx.attr.in_file[DirectoryPathInfo].directory.short_path,
                ctx.attr.in_file[DirectoryPathInfo].path,
            ])
            runfiles.append(ctx.attr.in_file[DirectoryPathInfo].directory)
        elif len(ctx.files.in_file) == 0:
            msg = "in file {} must provide files".format(ctx.attr.in_file.label)
            fail(msg)
        elif len(ctx.files.in_file) == 1:
            in_path = ctx.files.in_file[0].short_path
        else:
            msg = "in file {} must be a single file or a target that provides a DirectoryPathInfo".format(ctx.attr.in_file.label)
            fail(msg)

        out_path = "/".join([ctx.label.package, ctx.attr.out_file]) if ctx.label.package else ctx.attr.out_file
        paths.append((in_path, out_path))

    if is_windows:
        updater = _write_source_file_bat(ctx, paths)
    else:
        updater = _write_source_file_sh(ctx, paths)

    runfiles = ctx.runfiles(
        files = runfiles,
        transitive_files = ctx.attr.in_file.files if ctx.attr.in_file else None,
    )
    deps_runfiles = [dep[DefaultInfo].default_runfiles for dep in ctx.attr.additional_update_targets]
    if "merge_all" in dir(runfiles):
        runfiles = runfiles.merge_all(deps_runfiles)
    else:
        for dep in deps_runfiles:
            runfiles = runfiles.merge(dep)

    return [
        DefaultInfo(
            executable = updater,
            runfiles = runfiles,
        ),
        WriteSourceFileInfo(
            executable = updater,
        ),
    ]

_write_source_file = rule(
    attrs = _write_source_file_attrs,
    implementation = _write_source_file_impl,
    executable = True,
)

def _is_file_missing(label):
    """Check if a file is missing by passing its relative path through a glob()

    Args
        label: the file's label
    """
    file_abs = "%s/%s" % (label.package, label.name)
    file_rel = file_abs[len(native.package_name()) + 1:]
    file_glob = native.glob([file_rel], exclude_directories = 0)
    return len(file_glob) == 0
