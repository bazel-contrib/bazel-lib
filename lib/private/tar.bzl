"Implementation of tar rule"
_tar_attrs = {
    "args": attr.string_list(
        doc = "Additional flags permitted by BSD tar; see the man page.",
    ),
    "srcs": attr.label_list(
        doc = "Files and directories that are placed into the tar",
        mandatory = True,
        allow_files = True,
    ),
    "mode": attr.string(
        doc = """The first option to tar is a mode indicator from the following list:
       -c      Create a	new archive containing the specified items.  The  long
	       option form is --create.
       -r      Like  -c,  but  new  entries are	appended to the	archive.  Note
	       that this only works on uncompressed archives stored in regular
	       files.  The -f option is	required.  The	long  option  form  is
	       --append.
       -t      List  archive  contents	to  stdout.   The  long	option form is
	       --list.
       -u      Like -r,	but new	entries	are added only if they have a  modifi-
	       cation  date newer than the corresponding entry in the archive.
	       Note that this only works on uncompressed  archives  stored  in
	       regular	files.	 The  -f option	is required.  The long form is
	       --update.
       -x      Extract to disk from the	archive.  If a file with the same name
	       appears more than once in the archive, each copy	 will  be  ex-
	       tracted,	 with  later  copies  overwriting  (replacing) earlier
	       copies.	The long option	form is	--extract.
        """,
        values = ["create", "append", "list", "update", "extract"],
        default = "create",
    ),
    "mtree": attr.label(
        doc = "An mtree specification file",
        allow_single_file = True,
        # Mandatory since it's the only way to set constant timestamps
        mandatory = True,
    ),
    "out": attr.output(
        doc = "Resulting tar file to write. If absent, `[name].tar` is written.",
    ),
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

def _tar_impl(ctx):
    inputs = ctx.files.srcs[:]
    args = ctx.actions.args()
    if ctx.attr.mode != "create":
        fail("Only the 'create' mode is currently supported.")
    args.add("--" + ctx.attr.mode)

    args.add_all(ctx.attr.args)
    _add_compress_options(ctx.attr.compress, args)
    args.add_all(["-s", "#{}##".format(ctx.bin_dir.path)])

    out = ctx.outputs.out or ctx.actions.declare_file(ctx.attr.name + ".tar")
    args.add_all(["--file", out.path])

    args.add("@" + ctx.file.mtree.path)
    inputs.append(ctx.file.mtree)

    ctx.actions.run(
        executable = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"].tarinfo.binary,
        inputs = inputs,
        outputs = [out],
        arguments = [args],
        mnemonic = "Tar",
    )

    return DefaultInfo(files = depset([out]), runfiles = ctx.runfiles([out]))

def _mtree_line(file, uid = "0", gid = "0", time = "1672560000", mode = "0755"):
    return " ".join([
        file.short_path,
        "uid=" + uid,
        "gid=" + gid,
        "time=" + time,
        "mode=" + mode,
        "type=" + ("dir" if file.is_directory else "file"),
        "content=" + file.path,
    ])

def _mtree_impl(ctx):
    specification = []
    for s in ctx.files.srcs:
        specification.append(_mtree_line(s))
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
