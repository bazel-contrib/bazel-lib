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


