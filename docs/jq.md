<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for jq

<a id="#jq"></a>

## jq

<pre>
jq(<a href="#jq-name">name</a>, <a href="#jq-srcs">srcs</a>, <a href="#jq-filter">filter</a>, <a href="#jq-args">args</a>, <a href="#jq-out">out</a>)
</pre>

Invoke jq with a filter on a set of json input files.

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
    filter = """
        .[0] as $a
        # Take select fields from b.json
        | (.[1] | {foo, bar, tags}) as $b
        # Merge b onto a
        | ($a * $b)
        # Combine 'tags' array from both
        | .tags = ($a.tags + $b.tags)
        # Add new field
        + {\"aspect_is_cool\": true}
    """,
    args = ["--slurp"],
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="jq-name"></a>name |  Name of the rule   |  none |
| <a id="jq-srcs"></a>srcs |  List of input json files   |  none |
| <a id="jq-filter"></a>filter |  mandatory jq filter specification (https://stedolan.github.io/jq/manual/#Basicfilters)   |  none |
| <a id="jq-args"></a>args |  additional args to pass to jq   |  <code>[]</code> |
| <a id="jq-out"></a>out |  Name of the output json file; defaults to the rule name plus ".json"   |  <code>None</code> |


