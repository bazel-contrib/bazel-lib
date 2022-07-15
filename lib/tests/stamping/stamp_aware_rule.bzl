"Example of a rule that can version-stamp its outputs"

load("//lib:stamping.bzl", "STAMP_ATTRS", "maybe_stamp")

def _stamp_aware_rule_impl(ctx):
    args = ctx.actions.args()
    inputs = []
    outputs = [ctx.outputs.out]
    stamp = maybe_stamp(ctx)
    if stamp:
        args.add("--volatile_status_file", stamp.volatile_status_file)
        args.add("--stable_status_file", stamp.stable_status_file)

        inputs.extend([stamp.volatile_status_file, stamp.stable_status_file])

    ctx.actions.run_shell(
        inputs = inputs,
        arguments = [args],
        outputs = outputs,
        # In reality, this program would also read from the status files.
        command = "echo $@ > " + outputs[0].path,
    )
    return [DefaultInfo(files = depset(outputs))]

my_stamp_aware_rule = rule(
    implementation = _stamp_aware_rule_impl,
    attrs = dict({
        "out": attr.output(mandatory = True),
    }, **STAMP_ATTRS),
)
