<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API

<a id="#relative_file"></a>

## relative_file

<pre>
relative_file(<a href="#relative_file-to_file">to_file</a>, <a href="#relative_file-frm_file">frm_file</a>)
</pre>

Resolves a relative path between two files, "to_file" and "frm_file", they must share the same root

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="relative_file-to_file"></a>to_file |  the path with file name to resolve to, from frm   |  none |
| <a id="relative_file-frm_file"></a>frm_file |  the path with file name to resolve from   |  none |

**RETURNS**

The relative path from frm_file to to_file, including the file name


