"""A simple rule that generates and provides a DefaultOutput with some files"""

def _generate_outputs_impl(ctx):
    if len(ctx.attr.output_files) != len(ctx.attr.output_contents):
        fail("Number of output_files must match number of output_contents")
    outputs = []
    for i, file in enumerate(ctx.attr.output_files):
        content = ctx.attr.output_contents[i]
        out = ctx.actions.declare_file(file)

        # ctx.actions.write creates a FileWriteAction which uses UTF-8 encoding.
        ctx.actions.write(
            output = out,
            content = content,
        )
        outputs.append(out)

    provide = []
    if ctx.attr.output_group:
        kwargs = {ctx.attr.output_group: depset(outputs)}
        provide.append(OutputGroupInfo(**kwargs))
    else:
        provide.append(DefaultInfo(files = depset(outputs)))
    return provide

generate_outputs = rule(
    implementation = _generate_outputs_impl,
    provides = [DefaultInfo],
    attrs = {
        "output_files": attr.string_list(),
        "output_contents": attr.string_list(),
        "output_group": attr.string(),
    },
)
