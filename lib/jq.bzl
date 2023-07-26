"""Public API for jq"""

load("//lib/private:jq.bzl", _jq_lib = "jq_lib")

_jq_rule = rule(
    attrs = _jq_lib.attrs,
    implementation = _jq_lib.implementation,
    toolchains = ["@aspect_bazel_lib//lib:jq_toolchain_type"],
)

def jq(name, srcs, filter = None, filter_file = None, args = [], out = None, **kwargs):
    """Invoke jq with a filter on a set of json input files.

    For jq documentation, see https://stedolan.github.io/jq/.

    To use this rule you must register the jq toolchain in your WORKSPACE:

    ```starlark
    load("@aspect_bazel_lib//lib:repositories.bzl", "register_jq_toolchains")

    register_jq_toolchains()
    ```

    Usage examples:

    ```starlark
    load("@aspect_bazel_lib//lib:jq.bzl", "jq")

    # Create a new file bazel-out/.../no_srcs.json
    jq(
        name = "no_srcs",
        srcs = [],
        filter = ".name = \"Alice\"",
    )

    # Remove fields from package.json.
    # Writes to bazel-out/.../package.json which means you must refer to this as ":no_dev_deps"
    # since Bazel doesn't allow a label for the output file that collides with the input file.
    jq(
        name = "no_dev_deps",
        srcs = ["package.json"],
        filter = "del(.devDependencies)",
    )

    # Merge bar.json on top of foo.json, producing foobar.json
    jq(
        name = "merged",
        srcs = ["foo.json", "bar.json"],
        filter = ".[0] * .[1]",
        args = ["--slurp"],
        out = "foobar.json",
    )

    # Long filters can be split over several lines with comments
    jq(
        name = "complex",
        srcs = ["a.json", "b.json"],
        filter = \"\"\"
            .[0] as $a
            # Take select fields from b.json
            | (.[1] | {foo, bar, tags}) as $b
            # Merge b onto a
            | ($a * $b)
            # Combine 'tags' array from both
            | .tags = ($a.tags + $b.tags)
            # Add new field
            + {\\\"aspect_is_cool\\\": true}
        \"\"\",
        args = ["--slurp"],
    )

    # Load filter from a file
    jq(
        name = "merged",
        srcs = ["foo.json", "bar.json"],
        filter_file = "filter.txt",
        args = ["--slurp"],
        out = "foobar.json",
    )

    # Convert genquery output to json
    genquery(
        name = "deps",
        expression = "deps(//some:target)",
        scope = ["//some:target"],
    )

    jq(
        name = "deps_json",
        srcs = [":deps"],
        args = [
            "--raw-input",
            "--slurp",
        ],
        filter = "{ deps: split(\"\\n\") | map(select(. | length > 0)) }",
    )

    # With --stamp, causes properties to be replaced by version control info.
    jq(
        name = "stamped",
        srcs = ["package.json"],
        filter = "|".join([
            # Don't directly reference $STAMP as it's only set when stamping
            # This 'as' syntax results in $stamp being null in unstamped builds.
            "$ARGS.named.STAMP as $stamp",
            # Provide a default using the "alternative operator" in case $stamp is null.
            ".version = ($stamp.BUILD_EMBED_LABEL // \"<unstamped>\")",
        ]),
    )
    ```

    You could also use it directly from a `genrule` by referencing the toolchain, and the `JQ_BIN`
    "Make variable" it exposes:

    ```
    genrule(
        name = "case_genrule",
        srcs = ["a.json"],
        outs = ["genrule_output.json"],
        cmd = "$(JQ_BIN) '.' $(location a.json) > $@",
        toolchains = ["@jq_toolchains//:resolved_toolchain"],
    )
    ```

    Args:
        name: Name of the rule
        srcs: List of input files. May be empty.
        filter: Filter expression (https://stedolan.github.io/jq/manual/#Basicfilters).
            Subject to stamp variable replacements, see [Stamping](./stamping.md).
            When stamping is enabled, a variable named "STAMP" will be available in the filter.

            Be careful to write the filter so that it handles unstamped builds, as in the example above.

        filter_file: File containing filter expression (alternative to `filter`)
        args: Additional args to pass to jq
        out: Name of the output json file; defaults to the rule name plus ".json"
        **kwargs: Other common named parameters such as `tags` or `visibility`
    """
    default_name = name + ".json"
    if not out and not default_name in srcs:
        out = default_name

    _jq_rule(
        name = name,
        srcs = srcs,
        filter = filter,
        filter_file = filter_file,
        args = args,
        out = out,
        **kwargs
    )
