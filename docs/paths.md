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


<a id="#to_manifest_path"></a>

## to_manifest_path

<pre>
to_manifest_path(<a href="#to_manifest_path-ctx">ctx</a>, <a href="#to_manifest_path-file">file</a>)
</pre>

The runfiles manifest entry for a file

We must avoid using non-normalized paths (workspace/../other_workspace/path)
in order to locate entries by their key.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="to_manifest_path-ctx"></a>ctx |  starlark rule execution context   |  none |
| <a id="to_manifest_path-file"></a>file |  a File object   |  none |

**RETURNS**

a key that can lookup the path from the runfiles manifest


