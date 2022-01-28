"write_source_file implementation"

load("//lib:utils.bzl", "is_external_label")

_write_source_files_attrs = {
    "in_files": attr.label_list(allow_files = True, allow_empty = False, mandatory = True),
    "out_files": attr.label_list(allow_files = True, allow_empty = False, mandatory = True),
    "is_windows": attr.bool(mandatory = True),
}

def _write_source_files_impl(ctx):
    if ctx.attr.is_windows:
        fail("write_source_file is not yet implemented for windows")

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

    updater = ctx.actions.declare_file(
        ctx.label.name + "_update.sh",
    )

    ctx.actions.write(
        output = updater,
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
        ]),
    )

    return DefaultInfo(
        executable = updater,
        runfiles = ctx.runfiles(files = ctx.files.in_files),
    )

write_source_files_lib = struct(
    attrs = _write_source_files_attrs,
    implementation = _write_source_files_impl,
)
