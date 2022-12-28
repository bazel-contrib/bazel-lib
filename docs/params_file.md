<!-- Generated with Stardoc: http://skydoc.bazel.build -->

params_file public API




<a id="#params_file"></a>

## params_file

<pre>
params_file(<a href="#params_file-name">name</a>, <a href="#params_file-out">out</a>, <a href="#params_file-args">args</a>, <a href="#params_file-data">data</a>, <a href="#params_file-newline">newline</a>, <a href="#params_file-kwargs">kwargs</a>)
</pre>

Generates a UTF-8 encoded params file from a list of arguments.

Handles variable substitutions for args.


### **Parameters**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="params_file-name"></a>name |  Name of the rule.   |  none |
| <a id="params_file-out"></a>out |  Path of the output file, relative to this package.   |  none |
| <a id="params_file-args"></a>args |  Arguments to concatenate into a params file.<br><br>- Subject to 'Make variable' substitution. See https://docs.bazel.build/versions/main/be/make-variables.html.<br><br>- Subject to predefined source/output path variables substitutions.<br><br>  The predefined variables <code>execpath</code>, <code>execpaths</code>, <code>rootpath</code>, <code>rootpaths</code>, <code>location</code>, and <code>locations</code> take   label parameters (e.g. <code>$(execpath //foo:bar)</code>) and substitute the file paths denoted by that label.<br><br>  See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables for more info.<br><br>  NB: This $(location) substition returns the manifest file path which differs from the <code>*_binary</code> & <code>*_test</code>   args and genrule bazel substitions. This will be fixed in a future major release.   See docs string of <code>expand_location_into_runfiles</code> macro in <code>internal/common/expand_into_runfiles.bzl</code>   for more info.<br><br>- Subject to predefined variables & custom variable substitutions.<br><br>  Predefined "Make" variables such as <code>$(COMPILATION_MODE)</code> and <code>$(TARGET_CPU)</code> are expanded.   See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_variables.<br><br>  Custom variables are also expanded including variables set through the Bazel CLI with <code>--define=SOME_VAR=SOME_VALUE</code>.   See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables.<br><br>  Predefined genrule variables are not supported in this context.   |  <code>[]</code> |
| <a id="params_file-data"></a>data |  Data for <code>$(location)</code> expansions in args.   |  <code>[]</code> |
| <a id="params_file-newline"></a>newline |  Line endings to use. One of [<code>"auto"</code>, <code>"unix"</code>, <code>"windows"</code>].<br><br>- <code>"auto"</code> for platform-determined - <code>"unix"</code> for LF - <code>"windows"</code> for CRLF   |  <code>"auto"</code> |
| <a id="params_file-kwargs"></a>kwargs |  undocumented named arguments   |  none |


