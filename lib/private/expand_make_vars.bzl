"Helpers to expand make variables"

load("@bazel_skylib//lib:paths.bzl", _spaths = "paths")

def expand_locations(ctx, input, targets = []):
    """Expand location templates.

    Expands all `$(execpath ...)`, `$(rootpath ...)` and deprecated `$(location ...)` templates in the
    given string by replacing with the expanded path. Expansion only works for labels that point to direct dependencies
    of this rule or that are explicitly listed in the optional argument targets.

    See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables.

    Use `$(rootpath)` and `$(rootpaths)` to expand labels to the runfiles path that a built binary can use
    to find its dependencies. This path is of the format:
    - `./file`
    - `path/to/file`
    - `../external_repo/path/to/file`

    Use `$(execpath)` and `$(execpaths)` to expand labels to the execroot (where Bazel runs build actions).
    This is of the format:
    - `./file`
    - `path/to/file`
    - `external/external_repo/path/to/file`
    - `<bin_dir>/path/to/file`
    - `<bin_dir>/external/external_repo/path/to/file`

    The deprecated `$(location)` and `$(locations)` expansions returns either the execpath or rootpath depending on the context.

    Args:
      ctx: context
      input: String to be expanded
      targets: List of targets for additional lookup information.

    Returns:
      The expanded path or the original path
    """

    return ctx.expand_location(input, targets = targets)

def expand_variables(ctx, s, outs = [], output_dir = False, attribute_name = "args"):
    """Expand make variables and substitute like genrule does.

    This function is the same as ctx.expand_make_variables with the additional
    genrule-like substitutions of:

      - `$@`: The output file if it is a single file. Else triggers a build error.

      - `$(@D)`: The output directory.

        If there is only one file name in outs, this expands to the directory containing that file.

        If there is only one directory in outs, this expands to the single output directory.

        If there are multiple files, this instead expands to the package's root directory in the bin tree,
        even if all generated files belong to the same subdirectory!

      - `$(RULEDIR)`: The output directory of the rule, that is, the directory
        corresponding to the name of the package containing the rule under the bin tree.

    See https://docs.bazel.build/versions/main/be/general.html#genrule.cmd and
    https://docs.bazel.build/versions/main/be/make-variables.html#predefined_genrule_variables
    for more information of how these special variables are expanded.

    Args:
        ctx: starlark rule context
        s: expression to expand
        outs: declared outputs of the rule, for expanding references to outputs
        output_dir: whether the rule is expected to output a directory (TreeArtifact)
            Deprecated. For backward compatability with @aspect_bazel_lib 1.x. Pass
            output tree artifacts to outs instead.
        attribute_name: name of the attribute containing the expression

    Returns:
        `s` with the variables expanded
    """
    rule_dir = _spaths.join(
        ctx.bin_dir.path,
        ctx.label.workspace_root,
        ctx.label.package,
    )
    additional_substitutions = {}

    # TODO: remove output_dir in 2.x release
    if output_dir:
        if s.find("$@") != -1 or s.find("$(@)") != -1:
            fail("$@ substitution may only be used with output_dir=False.")

        # We'll write into a newly created directory named after the rule
        output_dir = _spaths.join(
            ctx.bin_dir.path,
            ctx.label.workspace_root,
            ctx.label.package,
            ctx.label.name,
        )
    else:
        if s.find("$@") != -1 or s.find("$(@)") != -1:
            if len(outs) > 1:
                fail("$@ substitution may only be used with a single out.")
        if len(outs) == 1:
            additional_substitutions["@"] = outs[0].path
            if outs[0].is_directory:
                output_dir = outs[0].path
            else:
                output_dir = outs[0].dirname
        else:
            output_dir = rule_dir

    additional_substitutions["@D"] = output_dir
    additional_substitutions["RULEDIR"] = rule_dir

    # Add some additional make variable substitutions for common useful values in the context
    additional_substitutions["BUILD_FILE_PATH"] = ctx.build_file_path
    additional_substitutions["VERSION_FILE"] = ctx.version_file.path
    additional_substitutions["INFO_FILE"] = ctx.info_file.path
    additional_substitutions["TARGET"] = "@%s//%s:%s" % (ctx.label.workspace_name, ctx.label.package, ctx.label.name)
    additional_substitutions["WORKSPACE"] = ctx.workspace_name

    return ctx.expand_make_variables(attribute_name, s, additional_substitutions)

def _expand_template_impl(ctx):
    template = ctx.file.template
    substitutions = ctx.attr.substitutions

    subs = dict({
        k: expand_locations(ctx, v, ctx.attr.data)
        for k, v in substitutions.items()
    }, **ctx.var)

    ctx.actions.expand_template(
        template = template,
        output = ctx.outputs.out,
        substitutions = subs,
        is_executable = ctx.attr.is_executable,
    )

expand_template = struct(
    doc = """Template expansion
    
This performs a simple search over the template file for the keys in substitutions,
and replaces them with the corresponding values.

Values may also use location templates as documented in [expand_locations](#expand_locations)
as well as [configuration variables] such as `$(BINDIR)`, `$(TARGET_CPU)`, and `$(COMPILATION_MODE)`.

[configuration variables]: https://docs.bazel.build/versions/main/skylark/lib/ctx.html#var
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
