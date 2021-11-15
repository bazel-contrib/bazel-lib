<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Copy files and directories to an output directory

<a id="#copy_to_directory"></a>

## copy_to_directory

<pre>
copy_to_directory(<a href="#copy_to_directory-name">name</a>, <a href="#copy_to_directory-is_windows">is_windows</a>, <a href="#copy_to_directory-replace_prefixes">replace_prefixes</a>, <a href="#copy_to_directory-root_paths">root_paths</a>, <a href="#copy_to_directory-srcs">srcs</a>)
</pre>

Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths` and `replace_prefixes` attributes.

NB: This rule is not yet implemented for Windows


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="copy_to_directory-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="copy_to_directory-is_windows"></a>is_windows |  -   | Boolean | required |  |
| <a id="copy_to_directory-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>If the output directory path for a file or directory starts with or is equal to a key in the dict then the matching portion of the output directory path is replaced with the dict value for that key.<br><br>Forward slashes (<code>/</code>) should be used as path separators. The final path segment of the key can be a partial match in the corresponding segment of the output directory path.<br><br>If there are multiple keys that match, the longest match wins.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="copy_to_directory-root_paths"></a>root_paths |  List of paths that are roots in the output directory. If a file or directory being copied is in one of the listed paths or one of its subpaths, the output directory path is the path relative to the root path instead of the path relative to the file's workspace.<br><br>Forward slashes (<code>/</code>) should be used as path separators. Partial matches on the final path segment of a root path against the corresponding segment in the full workspace relative path of a file are not matched.<br><br>If there are multiple root paths that match, the longest match wins.<br><br>Defaults to [package_name()] so that the output directory path of files in the target's package and and sub-packages are relative to the target's package and files outside of that retain their full workspace relative paths.   | List of strings | optional | [] |
| <a id="copy_to_directory-srcs"></a>srcs |  Files and/or directories to copy into the output directory   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#copy_to_directory_lib.impl"></a>

## copy_to_directory_lib.impl

<pre>
copy_to_directory_lib.impl(<a href="#copy_to_directory_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="copy_to_directory_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


