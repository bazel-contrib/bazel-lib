<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule that copies a directory to another place.

The rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command
on Windows (no Bash is required).


<a id="#copy_directory"></a>

## copy_directory

<pre>
copy_directory(<a href="#copy_directory-name">name</a>, <a href="#copy_directory-src">src</a>, <a href="#copy_directory-out">out</a>, <a href="#copy_directory-kwargs">kwargs</a>)
</pre>

Copies a directory to another location.

This rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command on Windows (no Bash is required).

If using this rule with source directories, it is recommended that you use the
`--host_jvm_args=-DBAZEL_TRACK_SOURCE_DIRECTORIES=1` startup option so that changes
to files within source directories are detected. See
https://github.com/bazelbuild/bazel/commit/c64421bc35214f0414e4f4226cc953e8c55fa0d2
for more context.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="copy_directory-name"></a>name |  Name of the rule.   |  none |
| <a id="copy_directory-src"></a>src |  A Label. The directory to make a copy of. (Can also be the label of a rule that generates a directory.)   |  none |
| <a id="copy_directory-out"></a>out |  Path of the output directory, relative to this package.   |  none |
| <a id="copy_directory-kwargs"></a>kwargs |  further keyword arguments, e.g. <code>visibility</code>   |  none |


