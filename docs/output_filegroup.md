<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule that copies source files to the output tree.

This rule uses a Bash command (diff) on Linux/macOS/non-Windows, and a cmd.exe
command (fc.exe) on Windows (no Bash is required).

Originally authored in rules_nodejs
https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/internal/common/copy_to_bin.bzl


<a id="output_file_action"></a>

## output_file_action

<pre>
output_file_action(<a href="#output_file_action-ctx">ctx</a>, <a href="#output_file_action-file">file</a>, <a href="#output_file_action-is_windows">is_windows</a>)
</pre>

Helper function that creates an action to copy a file to the output tree.

File are copied to the same workspace-relative path. The resulting files is
returned.

If the file passed in is already in the output tree is then it is returned
without a copy action.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="output_file_action-ctx"></a>ctx |  The rule context.   |  none |
| <a id="output_file_action-file"></a>file |  The file to copy.   |  none |
| <a id="output_file_action-is_windows"></a>is_windows |  Deprecated and unused   |  <code>None</code> |

**RETURNS**

A File in the output tree.


<a id="output_filegroup"></a>

## output_filegroup

<pre>
output_filegroup(<a href="#output_filegroup-name">name</a>, <a href="#output_filegroup-srcs">srcs</a>, <a href="#output_filegroup-kwargs">kwargs</a>)
</pre>

Copies a source file to output tree at the same workspace-relative path.

e.g. `<execroot>/path/to/file -> <execroot>/bazel-out/<platform>/bin/path/to/file`

If a file passed in is already in the output tree is then it is added directly to the
DefaultInfo provided by the rule without a copy.

This is useful to populate the output folder with all files needed at runtime, even
those which aren't outputs of a Bazel rule.

This way you can run a binary in the output folder (execroot or runfiles_root)
without that program needing to rely on a runfiles helper library or be aware that
files are divided between the source tree and the output tree.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="output_filegroup-name"></a>name |  Name of the rule.   |  none |
| <a id="output_filegroup-srcs"></a>srcs |  A list of labels. File(s) to copy.   |  none |
| <a id="output_filegroup-kwargs"></a>kwargs |  further keyword arguments, e.g. <code>visibility</code>   |  none |


<a id="output_files_actions"></a>

## output_files_actions

<pre>
output_files_actions(<a href="#output_files_actions-ctx">ctx</a>, <a href="#output_files_actions-files">files</a>, <a href="#output_files_actions-is_windows">is_windows</a>)
</pre>

Helper function that creates actions to copy files to the output tree.

Files are copied to the same workspace-relative path. The resulting list of
files is returned.

If a file passed in is already in the output tree is then it is added
directly to the result without a copy action.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="output_files_actions-ctx"></a>ctx |  The rule context.   |  none |
| <a id="output_files_actions-files"></a>files |  List of File objects.   |  none |
| <a id="output_files_actions-is_windows"></a>is_windows |  Deprecated and unused   |  <code>None</code> |

**RETURNS**

List of File objects in the output tree.


