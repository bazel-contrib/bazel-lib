<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A test rule that checks the executable permission on a file or directory.

<a id="executable_test"></a>

## executable_test

<pre>
load("@aspect_bazel_lib//lib:executable_test.bzl", "executable_test")

executable_test(<a href="#executable_test-name">name</a>, <a href="#executable_test-file">file</a>, <a href="#executable_test-executable">executable</a>, <a href="#executable_test-size">size</a>, <a href="#executable_test-kwargs">**kwargs</a>)
</pre>

A test that checks the executable permission on a file or directory.

The test succeeds if the executable permission matches <code>executable</code>.

On Windows, the test always succeeds.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="executable_test-name"></a>name |  The name of the test rule.   |  none |
| <a id="executable_test-file"></a>file |  Label of the file to check.   |  none |
| <a id="executable_test-executable"></a>executable |  Boolean; whether the file should be executable.   |  none |
| <a id="executable_test-size"></a>size |  standard attribute for tests   |  `"small"` |
| <a id="executable_test-kwargs"></a>kwargs |  The <a href="https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-tests">common attributes for tests</a>.   |  none |


