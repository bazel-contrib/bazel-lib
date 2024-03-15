<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Utilities for rules that expose resource_set on ctx.actions.run[_shell]

Workaround for https://github.com/bazelbuild/bazel/issues/15187

By default, Bazel allocates 1 cpu and 250M of RAM:
https://github.com/bazelbuild/bazel/blob/058f943037e21710837eda9ca2f85b5f8538c8c5/src/main/java/com/google/devtools/build/lib/actions/AbstractAction.java#L77


<a id="resource_set"></a>

## resource_set

<pre>
resource_set(<a href="#resource_set-attr">attr</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="resource_set-attr"></a>attr |  <p align="center"> - </p>   |  none |


