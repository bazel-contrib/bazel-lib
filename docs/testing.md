<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Helpers for making test assertions

<a id="assert_contains"></a>

## assert_contains

<pre>
assert_contains(<a href="#assert_contains-name">name</a>, <a href="#assert_contains-actual">actual</a>, <a href="#assert_contains-expected">expected</a>, <a href="#assert_contains-size">size</a>, <a href="#assert_contains-timeout">timeout</a>)
</pre>

Generates a test target which fails if the file doesn't contain the string.

Depends on bash, as it creates an sh_test target.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assert_contains-name"></a>name |  target to create   |  none |
| <a id="assert_contains-actual"></a>actual |  Label of a file   |  none |
| <a id="assert_contains-expected"></a>expected |  a string which should appear in the file   |  none |
| <a id="assert_contains-size"></a>size |  the size attribute of the test target   |  <code>None</code> |
| <a id="assert_contains-timeout"></a>timeout |  the timeout attribute of the test target   |  <code>None</code> |


<a id="assert_outputs"></a>

## assert_outputs

<pre>
assert_outputs(<a href="#assert_outputs-name">name</a>, <a href="#assert_outputs-actual">actual</a>, <a href="#assert_outputs-expected">expected</a>)
</pre>

Assert that the default outputs of a target are the expected ones.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="assert_outputs-name"></a>name |  name of the resulting diff_test   |  none |
| <a id="assert_outputs-actual"></a>actual |  string of the label to check the outputs   |  none |
| <a id="assert_outputs-expected"></a>expected |  a list of rootpaths of expected outputs, as they would appear in a runfiles manifest   |  none |


