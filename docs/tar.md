<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Wrapper to execute BSD tar

<a id="tar_rule"></a>

## tar_rule

<pre>
tar_rule(<a href="#tar_rule-name">name</a>, <a href="#tar_rule-mtree">mtree</a>, <a href="#tar_rule-out">out</a>, <a href="#tar_rule-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="tar_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="tar_rule-mtree"></a>mtree |  An mtree specification file   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="tar_rule-out"></a>out |  Resulting tar file to write   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional |  |
| <a id="tar_rule-srcs"></a>srcs |  Files that are placed into the tar   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |


<a id="tar"></a>

## tar

<pre>
tar(<a href="#tar-name">name</a>, <a href="#tar-out">out</a>, <a href="#tar-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="tar-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="tar-out"></a>out |  <p align="center"> - </p>   |  <code>None</code> |
| <a id="tar-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


