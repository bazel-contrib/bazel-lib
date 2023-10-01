"Implementation of tar rule"
_tar_attrs = {
    "srcs": attr.label_list(doc = "Files that are placed into the tar", mandatory = True, allow_files = True),
    "mtree": attr.label(doc = "An mtree specification file", allow_single_file = True),
    "out": attr.output(doc = "Resulting tar file to write"),
    "compress": attr.string(
        doc = "Compress the archive file with a supported algorithm.",
        values = ["bzip2", "compress", "gzip", "lrzip", "lz4", "lzma", "lzop", "xz", "zstd"],
    ),
}

def _add_compress_options(compress, args):
    if compress == "bzip2":
        args.add("--bzip2")
    if compress == "compress":
        args.add("--compress")
    if compress == "gzip":
        args.add("--gzip")
    if compress == "lrzip":
        args.add("--lrzip")
    if compress == "lzma":
        args.add("--lzma")
    if compress == "lz4":
        args.add("--lz4")
    if compress == "lzop":
        args.add("--lzop")
    if compress == "xz":
        args.add("--xz")
    if compress == "zstd":
        args.add("--zstd")

def _short_path(file):
    return file.short_path

def _tar_impl(ctx):
    tar_bin = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"].tarinfo.binary

    inputs = ctx.files.srcs[:]

    args = ctx.actions.args()
    _add_compress_options(ctx.attr.compress, args)
    args.add_all(["--cd", ctx.bin_dir.path])
    args.add("--create")

    out = ctx.outputs.out or ctx.actions.declare_file(ctx.attr.name + ".tar")
    args.add_all(["--file", out.path])

    if ctx.attr.mtree:
        args.add("@" + ctx.file.mtree.short_path)
        inputs.append(ctx.file.mtree)
    else:
        args.add_all(ctx.files.srcs, map_each = _short_path)

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
