<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for docs helpers

<a id="#stardoc_with_diff_test"></a>

## stardoc_with_diff_test

<pre>
stardoc_with_diff_test(<a href="#stardoc_with_diff_test-name">name</a>, <a href="#stardoc_with_diff_test-bzl_library_target">bzl_library_target</a>, <a href="#stardoc_with_diff_test-aspect_template">aspect_template</a>, <a href="#stardoc_with_diff_test-func_template">func_template</a>, <a href="#stardoc_with_diff_test-header_template">header_template</a>,
                       <a href="#stardoc_with_diff_test-provider_template">provider_template</a>, <a href="#stardoc_with_diff_test-rule_template">rule_template</a>, <a href="#stardoc_with_diff_test-suggested_update_target">suggested_update_target</a>)
</pre>

Creates a stardoc target, diff test, and an executable to rule to write the generated doc to the source tree and test that it's up to date.

This is helpful for minimizing boilerplate in repos wih lots of stardoc targets.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="stardoc_with_diff_test-name"></a>name |  the name of the stardoc file to be written to the current source directory (.md will be appended to the name). Call bazel run on this target to update the file.   |  none |
| <a id="stardoc_with_diff_test-bzl_library_target"></a>bzl_library_target |  the label of the <code>bzl_library</code> target to generate documentation for   |  none |
| <a id="stardoc_with_diff_test-aspect_template"></a>aspect_template |  the label or path to the Velocity aspect template to use with stardoc   |  <code>"@io_bazel_stardoc//stardoc:templates/markdown_tables/aspect.vm"</code> |
| <a id="stardoc_with_diff_test-func_template"></a>func_template |  the label or path to the Velocity function/macro template to use with stardoc   |  <code>"@io_bazel_stardoc//stardoc:templates/markdown_tables/func.vm"</code> |
| <a id="stardoc_with_diff_test-header_template"></a>header_template |  the label or path to the Velocity header template to use with stardoc   |  <code>"@io_bazel_stardoc//stardoc:templates/markdown_tables/header.vm"</code> |
| <a id="stardoc_with_diff_test-provider_template"></a>provider_template |  the label or path to the Velocity provider template to use with stardoc   |  <code>"@io_bazel_stardoc//stardoc:templates/markdown_tables/provider.vm"</code> |
| <a id="stardoc_with_diff_test-rule_template"></a>rule_template |  the label or path to the Velocity rule template to use with stardoc   |  <code>"@io_bazel_stardoc//stardoc:templates/markdown_tables/rule.vm"</code> |
| <a id="stardoc_with_diff_test-suggested_update_target"></a>suggested_update_target |  the target suggested to be run when a doc is out of date (should be the label for [update_docs](#update_docs))   |  <code>"//docs:update"</code> |


<a id="#update_docs"></a>

## update_docs

<pre>
update_docs(<a href="#update_docs-name">name</a>)
</pre>

Stamps an executable run for writing all stardocs declared with stardoc_with_diff_test to the source tree.

This is to be used in tandem with `stardoc_with_diff_test()` to produce a convenient workflow
for generating, testing, and updating all doc files as follows:

``` bash
bazel build //{docs_folder}/... && bazel test //{docs_folder}/... && bazel run //{docs_folder}:update
```

eg.

``` bash
bazel build //docs/... && bazel test //docs/... && bazel run //docs:update
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="update_docs-name"></a>name |  the name of executable target   |  <code>"update"</code> |


