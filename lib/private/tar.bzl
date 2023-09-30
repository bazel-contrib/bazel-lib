"Implementation of tar rule"
_tar_attrs = {
    "srcs": attr.label_list(doc = "Files that are placed into the tar", mandatory = True, allow_files = True),
    "mtree": attr.label(doc = "An mtree specification file", allow_single_file = True),
    "out": attr.output(doc = "Resulting tar file to write"),
}

def _tar_impl(ctx):
    tar_bin = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"].tarinfo.command
    out = ctx.outputs.out or ctx.actions.declare_file(ctx.attr.name + ".tar")
    args = ctx.actions.args()
    inputs = ctx.files.srcs[:]
    args.add_all(["--cd", ctx.bin_dir.path])
    args.add("--create")
    args.add_all(["--file", out.path])
    if ctx.attr.mtree:
        args.add("@" + ctx.file.mtree.short_path)
        inputs.append(ctx.file.mtree)

    ctx.actions.run(
        executable = tar_bin,
        inputs = inputs,
        outputs = [out],
        arguments = [args],
        mnemonic = "Tar",
    )

    return DefaultInfo(files = depset([out]), runfiles = ctx.runfiles([out]))

tar_lib = struct(
    attrs = _tar_attrs,
    implementation = _tar_impl,
)
