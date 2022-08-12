"expand_template rule"

load(":expand_locations.bzl", _expand_locations = "expand_locations")
load(":expand_variables.bzl", _expand_variables = "expand_variables")

def _expand_template_impl(ctx):
    template = ctx.file.template

    substitutions = {}
    for k, v in ctx.attr.substitutions.items():
        substitutions[k] = " ".join([_expand_variables(ctx, e, outs = [ctx.outputs.out], attribute_name = "substitutions") for e in _expand_locations(ctx, v, ctx.attr.data).split(" ")])

    ctx.actions.expand_template(
        template = template,
        output = ctx.outputs.out,
        substitutions = substitutions,
        is_executable = ctx.attr.is_executable,
    )

expand_template_lib = struct(
    doc = """Template expansion
    
This performs a simple search over the template file for the keys in substitutions,
and replaces them with the corresponding values.

Values may also use location templates as documented in
[expand_locations](https://github.com/aspect-build/bazel-lib/blob/main/docs/expand_make_vars.md#expand_locations)
as well as [configuration variables](https://docs.bazel.build/versions/main/skylark/lib/ctx.html#var)
such as `$(BINDIR)`, `$(TARGET_CPU)`, and `$(COMPILATION_MODE)` as documented in
[expand_variables](https://github.com/aspect-build/bazel-lib/blob/main/docs/expand_make_vars.md#expand_variables).
""",
    implementation = _expand_template_impl,
    attrs = {
        "template": attr.label(
            doc = "The template file to expand.",
            mandatory = True,
            allow_single_file = True,
        ),
        "substitutions": attr.string_dict(
            doc = "Mapping of strings to substitutions.",
            mandatory = True,
        ),
        "out": attr.output(
            doc = "Where to write the expanded file.",
            mandatory = True,
        ),
        "is_executable": attr.bool(
            doc = "Whether to mark the output file as executable.",
            default = False,
            mandatory = False,
        ),
        "data": attr.label_list(
            doc = "List of targets for additional lookup information.",
            allow_files = True,
        ),
    },
)

expand_template = rule(
    doc = expand_template_lib.doc,
    implementation = expand_template_lib.implementation,
    attrs = expand_template_lib.attrs,
)
