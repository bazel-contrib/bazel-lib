"write_source_file implementation"

load("//lib:utils.bzl", "is_external_label")

_WriteSourceFilesInfo = provider(
    "Provider to enforce deps are other write_source_files targets",
    fields = {
        "executable": "Generated update script",
    },
)

_write_source_files_attrs = {
    "in_files": attr.label_list(allow_files = True, allow_empty = False, mandatory = False),
    "out_files": attr.label_list(allow_files = True, allow_empty = False, mandatory = False),
    "additional_update_targets": attr.label_list(allow_files = False, providers = [_WriteSourceFilesInfo], mandatory = False),
    "is_windows": attr.bool(mandatory = True),
}

def _write_source_files_sh(ctx):
    updater = ctx.actions.declare_file(
        ctx.label.name + "_update.sh",
    )

    additional_update_scripts = [target[_WriteSourceFilesInfo].executable for target in ctx.attr.additional_update_targets]

    ctx.actions.write(
        output = updater,
        is_executable = True,
        content = """
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
runfiles_dir=$PWD
# BUILD_WORKSPACE_DIRECTORY not set when running as a test, uses the sandbox instead
if [[ ! -z "${BUILD_WORKSPACE_DIRECTORY:-}" ]]; then
    cd "$BUILD_WORKSPACE_DIRECTORY"
fi
""" + "\n".join([
            """
in=$runfiles_dir/{in_file}
out={out_file}

mkdir -p "$(dirname "$out")"
echo "Copying $in to $out in $PWD"
cp -f "$in" "$out"
chmod 644 "$out"
""".format(in_file = ctx.files.in_files[i].short_path, out_file = ctx.files.out_files[i].short_path)
            for i in range(len(ctx.attr.in_files))
        ]) + """
cd "$runfiles_dir"

# Run the update scripts for all write_source_file deps
""" + "\n".join(["""
{update_script}
""".format(update_script = update_script.short_path) for update_script in additional_update_scripts]),
    )

    return updater

def _write_source_files_bat(ctx):
    updater = ctx.actions.declare_file(
        ctx.label.name + "_update.bat",
    )

    additional_update_scripts = [target[_WriteSourceFilesInfo].executable for target in ctx.attr.additional_update_targets]

    content = """
@rem Generated by write_source_files.bzl, do not edit.
@echo off
set runfiles_dir=%cd%
if defined BUILD_WORKSPACE_DIRECTORY (
    cd %BUILD_WORKSPACE_DIRECTORY%
)
""" + "\n".join([
        """
set in=%runfiles_dir%\\{in_file}
set out={out_file}

if not defined BUILD_WORKSPACE_DIRECTORY (
    @rem Because there's no sandboxing in windows, if we copy over the target
    @rem file's symlink it will get copied back into the source directory
    @rem during tests. Work around this in tests by deleting the target file
    @rem symlink before copying over it.
    del %out%
)

echo Copying %in% to %out% in %cd%
copy %in% %out% >NUL
""".format(in_file = ctx.files.in_files[i].short_path.replace("/", "\\"), out_file = ctx.files.out_files[i].short_path).replace("/", "\\")
        for i in range(len(ctx.attr.in_files))
    ])  + """
cd %runfiles_dir%

@rem Run the update scripts for all write_source_file deps
""" + "\n".join(["""
call {update_script}
""".format(update_script = update_script.short_path) for update_script in additional_update_scripts])

    content = content.replace("\n", "\r\n")

    ctx.actions.write(
        output = updater,
        is_executable = True,
        content = content,
    )
    return updater

def _write_source_files_impl(ctx):
    if (len(ctx.attr.in_files) != len(ctx.attr.out_files)):
        fail("in_files and out_files must be the same length")

    for i in range(len(ctx.attr.in_files)):
        out_file_label = ctx.attr.out_files[i].label
        if is_external_label(out_file_label):
            fail("out file %s must be a source file in the user workspace" % out_file_label)

        if not ctx.files.out_files[i].is_source:
            fail("out file %s must be a source file, not a generated file" % out_file_label)

        if out_file_label.package != ctx.label.package:
            fail("out file %s (in package '%s') must be a source file within the target's package: '%s'" % (out_file_label, out_file_label.package, ctx.label.package))

    if ctx.attr.is_windows:
        updater = _write_source_files_bat(ctx)
    else:
        updater = _write_source_files_sh(ctx)

    runfiles = ctx.runfiles(files = ctx.files.in_files)
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
        _WriteSourceFilesInfo(
            executable = updater,
        ),
    ]

write_source_files_lib = struct(
    attrs = _write_source_files_attrs,
    implementation = _write_source_files_impl,
)
