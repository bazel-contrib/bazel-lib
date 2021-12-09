<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for jq

<a id="#jq"></a>

## jq

<pre>
jq(<a href="#jq-name">name</a>, <a href="#jq-srcs">srcs</a>, <a href="#jq-filter">filter</a>, <a href="#jq-args">args</a>, <a href="#jq-out">out</a>)
</pre>

Invoke jq with a filter on a set of json input files.

For jq documentation, see https://stedolan.github.io/jq/.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="jq-name"></a>name |  Name of the rule   |  none |
| <a id="jq-srcs"></a>srcs |  List of input json files   |  none |
| <a id="jq-filter"></a>filter |  mandatory jq filter specification (https://stedolan.github.io/jq/manual/#Basicfilters)   |  none |
| <a id="jq-args"></a>args |  additional args to pass to jq   |  <code>[]</code> |
| <a id="jq-out"></a>out |  Name of the output json file; defaults to the rule name plus ".json"   |  <code>None</code> |


