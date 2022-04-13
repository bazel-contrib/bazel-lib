<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule that copies source files to the output tree.

This rule uses a Bash command (diff) on Linux/macOS/non-Windows, and a cmd.exe
command (fc.exe) on Windows (no Bash is required).

Originally authored in rules_nodejs
https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/internal/common/copy_to_bin.bzl


<a id="#copy_to_bin"></a>

## copy_to_bin

<pre>
copy_to_bin(<a href="#copy_to_bin-name">name</a>, <a href="#copy_to_bin-srcs">srcs</a>, <a href="#copy_to_bin-kwargs">kwargs</a>)
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
| <a id="copy_to_bin-name"></a>name |  Name of the rule.   |  none |
| <a id="copy_to_bin-srcs"></a>srcs |  A list of labels. File(s) to copy.   |  none |
| <a id="copy_to_bin-kwargs"></a>kwargs |  further keyword arguments, e.g. <code>visibility</code>   |  none |


