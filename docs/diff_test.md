<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A test rule that compares two binary files or two directories.

Similar to `bazel-skylib`'s [`diff_test`](https://github.com/bazelbuild/bazel-skylib/blob/main/rules/diff_test.bzl)
but also supports comparing directories.

The rule uses a Bash command (diff) on Linux/macOS/non-Windows, and a cmd.exe
command (fc.exe) on Windows (no Bash is required).


<a id="diff_test"></a>

## diff_test

<pre>
diff_test(<a href="#diff_test-name">name</a>, <a href="#diff_test-file1">file1</a>, <a href="#diff_test-file2">file2</a>, <a href="#diff_test-size">size</a>, <a href="#diff_test-timeout">timeout</a>, <a href="#diff_test-kwargs">kwargs</a>)
</pre>

A test that compares two files.

The test succeeds if the files' contents match.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="diff_test-name"></a>name |  The name of the test rule.   |  none |
| <a id="diff_test-file1"></a>file1 |  Label of the file to compare to &lt;code&gt;file2&lt;/code&gt;.   |  none |
| <a id="diff_test-file2"></a>file2 |  Label of the file to compare to &lt;code&gt;file1&lt;/code&gt;.   |  none |
| <a id="diff_test-size"></a>size |  standard attribute for tests   |  <code>None</code> |
| <a id="diff_test-timeout"></a>timeout |  standard attribute for tests. Defaults to "short" if both timeout and size are unspecified.   |  <code>None</code> |
| <a id="diff_test-kwargs"></a>kwargs |  The &lt;a href="https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-tests"&gt;common attributes for tests&lt;/a&gt;.   |  none |


