<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API

<a id="chdir_binary"></a>

## chdir_binary

<pre>
chdir_binary(<a href="#chdir_binary-name">name</a>, <a href="#chdir_binary-binary">binary</a>, <a href="#chdir_binary-chdir">chdir</a>, <a href="#chdir_binary-kwargs">kwargs</a>)
</pre>

Wrap a *_binary to be executed under a given directory.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="chdir_binary-name"></a>name |  Name of the rule.   |  none |
| <a id="chdir_binary-binary"></a>binary |  Label of an executable target to wrap.   |  none |
| <a id="chdir_binary-chdir"></a>chdir |  Argument for the <code>cd</code> command, the default is commonly used with <code>bazel run</code> to run the program in the root of the Bazel workspace, in the source tree.   |  <code>"$BUILD_WORKSPACE_DIRECTORY"</code> |
| <a id="chdir_binary-kwargs"></a>kwargs |  Additional named arguments for the resulting sh_binary rule.   |  none |


<a id="relative_file"></a>

## relative_file

<pre>
relative_file(<a href="#relative_file-to_file">to_file</a>, <a href="#relative_file-frm_file">frm_file</a>)
</pre>

Resolves a relative path between two files, "to_file" and "frm_file".

If neither of the paths begin with ../ it is assumed that they share the same root. When finding the relative path,
the incoming files are treated as actual files (not folders) so the resulting relative path may differ when compared
to passing the same arguments to python's "os.path.relpath()" or NodeJs's "path.relative()".

For example, 'relative_file("../foo/foo.txt", "bar/bar.txt")' will return '../../foo/foo.txt'


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="relative_file-to_file"></a>to_file |  the path with file name to resolve to, from frm   |  none |
| <a id="relative_file-frm_file"></a>frm_file |  the path with file name to resolve from   |  none |

**RETURNS**

The relative path from frm_file to to_file, including the file name


<a id="to_manifest_path"></a>

## to_manifest_path

<pre>
to_manifest_path(<a href="#to_manifest_path-ctx">ctx</a>, <a href="#to_manifest_path-file">file</a>)
</pre>

The runfiles manifest entry path for a file

This is the full runfiles path of a file including its workspace name as
the first segment. We refert to it as the manifest path as it is the path
flavor that is used for in the runfiles MANIFEST file.

We must avoid using non-normalized paths (workspace/../other_workspace/path)
in order to locate entries by their key.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="to_manifest_path-ctx"></a>ctx |  starlark rule execution context   |  none |
| <a id="to_manifest_path-file"></a>file |  a File object   |  none |

**RETURNS**

The runfiles manifest entry path for a file


<a id="to_output_relative_path"></a>

## to_output_relative_path

<pre>
to_output_relative_path(<a href="#to_output_relative_path-f">f</a>)
</pre>

The relative path from bazel-out/[arch]/bin to the given File object

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="to_output_relative_path-f"></a>f |  <p align="center"> - </p>   |  none |


<a id="to_workspace_path"></a>

## to_workspace_path

<pre>
to_workspace_path(<a href="#to_workspace_path-file">file</a>)
</pre>

The workspace relative path for a file

This is the full runfiles path of a file excluding its workspace name.
This differs from root path and manifest path as it does not include the
repository name if the file is from an external repository.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="to_workspace_path-file"></a>file |  a File object   |  none |

**RETURNS**

The workspace relative path for a file


