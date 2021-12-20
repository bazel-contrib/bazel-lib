"""Implementation for jq rule"""

_jq_attrs = {
    "srcs": attr.label_list(
        allow_files = [".json"],
        mandatory = True,
        allow_empty = True,
    ),
    "filter": attr.string(),
    "filter_file": attr.label(allow_single_file = True),
    "args": attr.string_list(),
    "out": attr.output(mandatory = True),
}

def _jq_impl(ctx):
    jq_bin = ctx.toolchains["@aspect_bazel_lib//lib:jq_toolchain_type"].jqinfo.bin

    out = ctx.outputs.out
    args = ctx.attr.args
    inputs = ctx.files.srcs[:]

    if not ctx.attr.filter and not ctx.attr.filter_file:
        fail("Must provide a filter or a filter_file")
    if ctx.attr.filter and ctx.attr.filter_file:
        fail("Cannot provide both a filter and a filter_file")

    # jq hangs when there are no input sources unless --null-input flag is passed
    if len(ctx.attr.srcs) == 0 and "-n" not in args and "--null-input" not in args:
        args = args + ["--null-input"]

    if ctx.attr.filter_file:
        args = args + ["--from-file '%s'" % ctx.file.filter_file.path]
        inputs.append(ctx.file.filter_file)

    cmd = "{jq} {args} {filter} {sources} > {out}".format(
        jq = jq_bin.path,
        args = " ".join(args),
        filter = "'%s'" % ctx.attr.filter if ctx.attr.filter else "",
        sources = " ".join(["'%s'" % file.path for file in ctx.files.srcs]),
        out = out.path,
    )

    ctx.actions.run_shell(
        tools = [jq_bin],
        inputs = inputs,
        outputs = [out],
        command = cmd,
    )

    return DefaultInfo(files = depset([out]), runfiles = ctx.runfiles([out]))

jq_lib = struct(
    attrs = _jq_attrs,
    implementation = _jq_impl,
)
