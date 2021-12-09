"""Implementation for jq rule"""

_jq_attrs = {
    "srcs": attr.label_list(
        allow_files = [".json"],
        mandatory = True,
        allow_empty = True,
    ),
    "filter": attr.string(
        mandatory = True,
    ),
    "args": attr.string_list(),
    "out": attr.output(mandatory = True),
}

def _jq_impl(ctx):
    jq_bin = ctx.toolchains["@aspect_bazel_lib//lib:jq_toolchain_type"].jqinfo.bin

    out = ctx.outputs.out
    args = ctx.attr.args

    # jq hangs when there are no input sources unless --null-input flag is passed
    if len(ctx.attr.srcs) == 0 and "-n" not in args and "--null-input" not in args:
        args = args + ["--null-input"]

    cmd = "{jq} {args} '{filter}' {sources} > {out}".format(
        jq = jq_bin.path,
        args = " ".join(args),
        filter = ctx.attr.filter,
        sources = " ".join(["'%s'" % file.path for file in ctx.files.srcs]),
        out = out.path,
    )

    ctx.actions.run_shell(
        tools = [jq_bin],
        inputs = ctx.files.srcs,
        outputs = [out],
        command = cmd,
    )

    return DefaultInfo(files = depset([out]), runfiles = ctx.runfiles([out]))

jq_lib = struct(
    attrs = _jq_attrs,
    implementation = _jq_impl,
)
