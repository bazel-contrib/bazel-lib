<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Re-export of https://registry.bazel.build/modules/yq.bzl to avoid breaking change.
TODO(3.0): delete

<a id="yq"></a>

## yq

<pre>
load("@aspect_bazel_lib//lib:yq.bzl", "yq")

yq(<a href="#yq-name">name</a>, <a href="#yq-srcs">srcs</a>, <a href="#yq-expression">expression</a>, <a href="#yq-args">args</a>, <a href="#yq-outs">outs</a>, <a href="#yq-kwargs">**kwargs</a>)
</pre>

Invoke yq with an expression on a set of input files.

yq is capable of parsing and outputting to other formats. See their [docs](https://mikefarah.gitbook.io/yq) for more examples.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="yq-name"></a>name |  Name of the rule   |  none |
| <a id="yq-srcs"></a>srcs |  List of input file labels   |  none |
| <a id="yq-expression"></a>expression |  yq expression (https://mikefarah.gitbook.io/yq/commands/evaluate).<br><br>Defaults to the identity expression ".". Subject to stamp variable replacements, see [Stamping](./stamping.md). When stamping is enabled, an environment variable named "STAMP" will be available in the expression.<br><br>Be careful to write the filter so that it handles unstamped builds, as in the example above.   |  `"."` |
| <a id="yq-args"></a>args |  Additional args to pass to yq.<br><br>Note that you do not need to pass _eval_ or _eval-all_ as this is handled automatically based on the number `srcs`. Passing the output format or the parse format is optional as these can be guessed based on the file extensions in `srcs` and `outs`.   |  `[]` |
| <a id="yq-outs"></a>outs |  Name of the output files.<br><br>Defaults to a single output with the name plus a ".yaml" extension, or the extension corresponding to a passed output argument (e.g., "-o=json"). For split operations you must declare all outputs as the name of the output files depends on the expression.   |  `None` |
| <a id="yq-kwargs"></a>kwargs |  Other common named parameters such as `tags` or `visibility`   |  none |


