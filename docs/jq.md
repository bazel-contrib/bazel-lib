<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Re-export of https://registry.bazel.build/modules/jq.bzl to avoid breaking change.
TODO(3.0): delete

<a id="jq"></a>

## jq

<pre>
load("@aspect_bazel_lib//lib:jq.bzl", "jq")

jq(<a href="#jq-name">name</a>, <a href="#jq-srcs">srcs</a>, <a href="#jq-filter">filter</a>, <a href="#jq-filter_file">filter_file</a>, <a href="#jq-args">args</a>, <a href="#jq-out">out</a>, <a href="#jq-data">data</a>, <a href="#jq-expand_args">expand_args</a>, <a href="#jq-kwargs">**kwargs</a>)
</pre>

Invoke jq with a filter on a set of json input files.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="jq-name"></a>name |  Name of the rule   |  none |
| <a id="jq-srcs"></a>srcs |  List of input files. May be empty.   |  none |
| <a id="jq-filter"></a>filter |  Filter expression (https://stedolan.github.io/jq/manual/#Basicfilters). Subject to stamp variable replacements, see [Stamping](./stamping.md). When stamping is enabled, a variable named "STAMP" will be available in the filter.<br><br>Be careful to write the filter so that it handles unstamped builds, as in the example above.   |  `None` |
| <a id="jq-filter_file"></a>filter_file |  File containing filter expression (alternative to `filter`)   |  `None` |
| <a id="jq-args"></a>args |  Additional args to pass to jq   |  `[]` |
| <a id="jq-out"></a>out |  Name of the output json file; defaults to the rule name plus ".json"   |  `None` |
| <a id="jq-data"></a>data |  List of additional files. May be empty.   |  `[]` |
| <a id="jq-expand_args"></a>expand_args |  Run bazel's location and make variable expansion on the args.   |  `False` |
| <a id="jq-kwargs"></a>kwargs |  Other common named parameters such as `tags` or `visibility`   |  none |


