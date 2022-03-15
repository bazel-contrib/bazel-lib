"""A simple rule that generates provides a DefaultOutput with some files"""

def _impl(ctx):
    if len(ctx.attr.out_files) != len(ctx.attr.out_contents):
        fail("Number of out_files must match number of out_contents")
    outputs = []
    for i, file in enumerate(ctx.attr.out_files):
        content = ctx.attr.out_contents[i]
        out = ctx.actions.declare_file(file)

        # ctx.actions.write creates a FileWriteAction which uses UTF-8 encoding.
        ctx.actions.write(
            output = out,
            content = content,
        )
        outputs.append(out)

    return [DefaultInfo(
        files = depset(direct = outputs),
        runfiles = ctx.runfiles(files = outputs),
    )]

default_output_gen = rule(
    implementation = _impl,
    provides = [DefaultInfo],
    attrs = {
        "out_files": attr.string_list(),
        "out_contents": attr.string_list(),
    },
)
