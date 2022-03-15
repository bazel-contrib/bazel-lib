<!-- Generated with Stardoc: http://skydoc.bazel.build -->

A rule that provides file(s) from a given target's DefaultInfo


<a id="#default_info_files"></a>

## default_info_files

<pre>
default_info_files(<a href="#default_info_files-name">name</a>, <a href="#default_info_files-paths">paths</a>, <a href="#default_info_files-target">target</a>)
</pre>

A rule that provides file(s) from a given target's DefaultInfo

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="default_info_files-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="default_info_files-paths"></a>paths |  the paths of the files to provide in the DefaultInfo of the target relative to its root   | List of strings | required |  |
| <a id="default_info_files-target"></a>target |  the target to look in for requested paths in its' DefaultInfo   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#make_default_info_files"></a>

## make_default_info_files

<pre>
make_default_info_files(<a href="#make_default_info_files-name">name</a>, <a href="#make_default_info_files-target">target</a>, <a href="#make_default_info_files-paths">paths</a>)
</pre>

Helper function to generate a default_info_files target and return its label.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="make_default_info_files-name"></a>name |  unique name for the generated <code>default_info_files</code> target.   |  none |
| <a id="make_default_info_files-target"></a>target |  the target to look in for requested paths in its' DefaultInfo   |  none |
| <a id="make_default_info_files-paths"></a>paths |  the paths of the files to provide in the DefaultInfo of the target relative to its root   |  none |

**RETURNS**

The label `name`


