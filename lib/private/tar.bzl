"Implementation of tar rule"
_tar_attrs = {
    "args": attr.string_list(doc = "Additional flags permitted by BSD tar --create"),
    "srcs": attr.label_list(doc = "Files that are placed into the tar", mandatory = True, allow_files = True),
    "mtree": attr.label(doc = "An mtree specification file", allow_single_file = True),
    "out": attr.output(doc = "Resulting tar file to write"),
    "compress": attr.string(
        doc = "Compress the archive file with a supported algorithm.",
        values = ["bzip2", "compress", "gzip", "lrzip", "lz4", "lzma", "lzop", "xz", "zstd"],
    ),
}

_mtree_attrs = {
    "srcs": attr.label_list(doc = "Files that are placed into the tar", mandatory = True, allow_files = True),
    "out": attr.output(doc = "Resulting specification file to write"),
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
    args.add("--create")
    args.add_all(ctx.attr.args)
    _add_compress_options(ctx.attr.compress, args)
    args.add_all(["--cd", ctx.bin_dir.path])

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

def _mtree_line(path, uid = "0", gid = "0", time = "1672560000", mode = "0755", type_ = "file"):
    return " ".join([
        path,
        "uid=" + uid,
        "gid=" + gid,
        "time=" + time,
        "mode=" + mode,
        "type=" + type_,
    ])

def _mtree_impl(ctx):
    specification = []
    for s in ctx.files.srcs:
        specification.append(_mtree_line(s.short_path))
    ctx.actions.write(ctx.outputs.out, "\n".join(specification + [""]))
    return DefaultInfo(files = depset([ctx.outputs.out]), runfiles = ctx.runfiles([ctx.outputs.out]))

tar_lib = struct(
    attrs = _tar_attrs,
    implementation = _tar_impl,
    mtree_attrs = _mtree_attrs,
    mtree_implementation = _mtree_impl,
)

tar = rule(
    doc = "Rule that executes BSD `tar`. Most users should use the [`tar`](#tar) macro, rather than load this directly.",
    implementation = tar_lib.implementation,
    attrs = tar_lib.attrs,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
)
