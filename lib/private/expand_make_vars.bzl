"Helpers to expand make variables"

# Convert an runfiles rootpath to a runfiles manifestpath.
# Runfiles rootpath is returned from ctx.expand_location $(rootpath) and $(rootpaths):
# - ./file
# - path/to/file
# - ../external_repo/path/to/file
# This is converted to the runfiles manifest path of:
# - repo/path/to/file
def _rootpath_to_runfiles_manifest_path(ctx, path, targets):
    if path.startswith("../"):
        return path[len("../"):]
    if path.startswith("./"):
        path = path[len("./"):]
    return ctx.workspace_name + "/" + path

# Expand $(rootpath) and $(rootpaths) to runfiles manifest path.
# Runfiles manifest path is of the form:
# - repo/path/to/file
def _expand_rootpath_to_manifest_path(ctx, input, targets):
    paths = ctx.expand_location(input, targets)
    return " ".join([_rootpath_to_runfiles_manifest_path(ctx, p, targets) for p in paths.split(" ")])

def expand_locations(ctx, input, targets = []):
    """Expand location templates.

    Expands all `$(execpath ...)`, `$(rootpath ...)` and legacy `$(location ...)` templates in the
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

    The legacy `$(location)` and `$(locations)` expansions are deprecated as they return the runfiles manifest path of the
    format `repo/path/to/file` which behave differently than the built-in `$(location)` expansion in args of *_binary
    and *_test rules which returns the rootpath.
    See https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-binaries.

    The legacy `$(location)` and `$(locations)` expansion also differs from how the builtin `ctx.expand_location()` expansions
    of `$(location)` and `$(locations)` behave as that function returns either the execpath or rootpath depending on the context.
    See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables.

    The behavior of `$(location)` and `$(locations)` expansion will be fixed in a future major release to match the
    to default Bazel behavior and return the same path as `ctx.expand_location()` returns for these.

    The recommended approach is to now use `$(rootpath)` where you previously used $(location). See the docstrings
    of `nodejs_binary` or `params_file` for examples of how to use `$(rootpath)` in `templated_args` and `args` respectively.

    Args:
      ctx: context
      input: String to be expanded
      targets: List of targets for additional lookup information.

    Returns:
      The expanded path or the original path
    """
    target = "@%s//%s:%s" % (ctx.workspace_name, "/".join(ctx.build_file_path.split("/")[:-1]), ctx.attr.name)

    # Loop through input an expand all predefined source/output path variables
    # See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables.
    path = ""
    length = len(input)
    last = 0
    for i in range(length):
        # Support legacy $(location) and $(locations) expansions which return the runfiles manifest path
        # in the format `repo/path/to/file`. This expansion is DEPRECATED. See docstring above.
        # TODO: Change location to behave the same as the built-in $(location) expansion for args of *_binary
        #       and *_test rules. This would be a BREAKING CHANGE.
        if input[i:].startswith("$(location ") or input[i:].startswith("$(locations "):
            j = input.find(")", i) + 1
            if (j == 0):
                fail("invalid \"%s\" expansion in string \"%s\" part of target %s" % (input[i:j], input, target))
            path += input[last:i]
            path += _expand_rootpath_to_manifest_path(ctx, "$(rootpath" + input[i + 10:j], targets)
            last = j
            i = j

        # Expand $(execpath) $(execpaths) $(rootpath) $(rootpaths) with plain ctx.expand_location()
        if input[i:].startswith("$(execpath ") or input[i:].startswith("$(execpaths ") or input[i:].startswith("$(rootpath ") or input[i:].startswith("$(rootpaths "):
            j = input.find(")", i) + 1
            if (j == 0):
                fail("invalid \"%s\" expansion in string \"%s\" part of target %s" % (input[i:j], input, target))
            path += input[last:i]
            path += ctx.expand_location(input[i:j], targets)
            last = j
            i = j
    path += input[last:]

    return path

def expand_variables(ctx, s, outs = [], output_dir = False, attribute_name = "args"):
    """Expand make variables and substitute like genrule does.

    This function is the same as ctx.expand_make_variables with the additional
    genrule-like substitutions of:

      - $@: The output file if it is a single file. Else triggers a build error.
      - $(@D): The output directory. If there is only one file name in outs,
               this expands to the directory containing that file. If there are multiple files,
               this instead expands to the package's root directory in the bin tree,
               even if all generated files belong to the same subdirectory!
      - $(RULEDIR): The output directory of the rule, that is, the directory
        corresponding to the name of the package containing the rule under the bin tree.

    See https://docs.bazel.build/versions/main/be/general.html#genrule.cmd and
    https://docs.bazel.build/versions/main/be/make-variables.html#predefined_genrule_variables
    for more information of how these special variables are expanded.

    Args:
        ctx: starlark rule context
        s: expression to expand
        outs: declared outputs of the rule, for expanding references to outputs
        output_dir: whether the rule is expected to output a directory (TreeArtifact)
        attribute_name: name of the attribute containing the expression

    Returns:
        s with the variables expanded
    """
    rule_dir = [f for f in [
        ctx.bin_dir.path,
        ctx.label.workspace_root,
        ctx.label.package,
    ] if f]
    additional_substitutions = {}

    if output_dir:
        if s.find("$@") != -1 or s.find("$(@)") != -1:
            fail("$@ substitution may only be used with output_dir=False.")

        # We'll write into a newly created directory named after the rule
        output_dir = [f for f in [
            ctx.bin_dir.path,
            ctx.label.workspace_root,
            ctx.label.package,
            ctx.label.name,
        ] if f]
    else:
        if s.find("$@") != -1 or s.find("$(@)") != -1:
            if len(outs) > 1:
                fail("$@ substitution may only be used with a single out.")
        if len(outs) == 1:
            additional_substitutions["@"] = outs[0].path
            output_dir = outs[0].dirname.split("/")
        else:
            output_dir = rule_dir[:]

    # The list comprehension removes empty segments like if we are in the root package
    additional_substitutions["@D"] = "/".join([o for o in output_dir if o])
    additional_substitutions["RULEDIR"] = "/".join([o for o in rule_dir if o])

    return ctx.expand_make_variables(attribute_name, s, additional_substitutions)
