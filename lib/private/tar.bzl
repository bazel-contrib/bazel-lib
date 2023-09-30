"Implementation of tar rule"
_tar_attrs = {
    "args": attr.string_list(doc = "Additional flags permitted by BSD tar --create"),
    "srcs": attr.label_list(doc = "Files that are placed into the tar", mandatory = True, allow_files = True),
    "mtree": attr.label(doc = "An mtree specification file", allow_single_file = True),
    "gid": attr.string(doc = """\
        Use the provided group id number.  On extract, this overrides
	    the group id in the archive; the group name in the archive will
	    be  ignored. On create, this overrides the group id read from
	    disk; if --gname is not also specified, the group name will be
	    set to match the group id.
        """, default = "0"),
    "gname": attr.string(doc = """\
        Use the provided  group name. On extract, this overrides the
	    group name in the archive; if the provided group name does not
	    exist on the system, the group id (from the archive or from the
	    --gid option) will be used instead. On create, this sets the
	    group name that will be stored in the archive; the name will
	    not be verified against the system group database.
        """),
    "uid": attr.string(doc = """\
        Use the provided user id number and ignore the user name from
	    the archive.  On create, if --uname is not also specified,  the
	    user name will be set to match the user id.
    """, default = "0"),
    "uname": attr.string(doc = """\
        Use the provided user name.	On extract, this overrides the
	    user name in the archive; if the provided user name  does  not
	    exist  on  the system, it will be ignored and the user id (from
	    the archive or from the --uid option) will be used instead.  On
	    create, this sets the user name that  will  be  stored  in  the
	    archive; the name is not verified against the system user data-
	    base.
    """),
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
    args.add("--create")
    args.add_all(ctx.attr.args)
    _add_compress_options(ctx.attr.compress, args)
    args.add_all(["--cd", ctx.bin_dir.path])
    if ctx.attr.gname:
        args.add_all(["--gname", ctx.attr.gname])
    if ctx.attr.uname:
        args.add_all(["--uname", ctx.attr.uname])
    if ctx.attr.gid:
        args.add_all(["--gid", ctx.attr.gid])
    if ctx.attr.uid:
        args.add_all(["--uid", ctx.attr.uid])

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
