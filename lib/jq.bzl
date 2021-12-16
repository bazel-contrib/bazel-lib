"""Public API for jq"""

load("//lib/private:jq.bzl", _jq_lib = "jq_lib")

_jq_rule = rule(
    attrs = _jq_lib.attrs,
    implementation = _jq_lib.implementation,
    toolchains = ["@aspect_bazel_lib//lib:jq_toolchain_type"],
)

def jq(name, srcs, filter, args = [], out = None):
    """Invoke jq with a filter on a set of json input files.

    For jq documentation, see https://stedolan.github.io/jq/.

    Usage examples:

    ```starlark
    # Remove fields from package.json
    jq(
        name = "no_dev_deps",
        srcs = ["package.json"],
        filter = "del(.devDependencies)",
    )

    # Merge bar.json on top of foo.json
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
    ```

    Args:
        name: Name of the rule
        srcs: List of input json files
        filter: mandatory jq filter specification (https://stedolan.github.io/jq/manual/#Basicfilters)
        args: additional args to pass to jq
        out: Name of the output json file; defaults to the rule name plus ".json"
    """
    if not out:
        out = name + ".json"

    _jq_rule(
        name = name,
        srcs = srcs,
        filter = filter,
        args = args,
        out = out,
    )
