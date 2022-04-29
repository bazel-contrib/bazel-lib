<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths`, `exclude_prefixes` and `replace_prefixes` attributes.


<a id="#copy_to_directory"></a>

## copy_to_directory

<pre>
copy_to_directory(<a href="#copy_to_directory-name">name</a>, <a href="#copy_to_directory-exclude_prefixes">exclude_prefixes</a>, <a href="#copy_to_directory-include_external_repositories">include_external_repositories</a>, <a href="#copy_to_directory-replace_prefixes">replace_prefixes</a>,
                  <a href="#copy_to_directory-root_paths">root_paths</a>, <a href="#copy_to_directory-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="copy_to_directory-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="copy_to_directory-exclude_prefixes"></a>exclude_prefixes |  List of path prefixes to exclude from output directory.<br><br>        If the output directory path for a file or directory starts with or is equal to         a path in the list then that file is not copied to the output directory.<br><br>        Exclude prefixes are matched *before* replace_prefixes are applied.   | List of strings | optional | [] |
| <a id="copy_to_directory-include_external_repositories"></a>include_external_repositories |  List of external repository names to include in the output directory.<br><br>        Files from external repositories are not copied into the output directory unless         the external repository they come from is listed here.<br><br>        When copied from an external repository, the file path in the output directory         defaults to the file's path within the external repository. The external repository         name is _not_ included in that path.<br><br>        For example, the following copies <code>@external_repo//path/to:file</code> to         <code>path/to/file</code> within the output directory.<br><br>        <pre><code>         copy_to_directory(             name = "dir",             include_external_repositories = ["external_repo"],             srcs = ["@external_repo//path/to:file"],         )         </code></pre><br><br>        Files from external repositories are subject to <code>root_paths</code>, <code>exclude_prefixes</code>         and <code>replace_prefixes</code> in the same way as files form the main repository.   | List of strings | optional | [] |
| <a id="copy_to_directory-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>        If the output directory path for a file or directory starts with or is equal to         a key in the dict then the matching portion of the output directory path is         replaced with the dict value for that key.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        If there are multiple keys that match, the longest match wins.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="copy_to_directory-root_paths"></a>root_paths |  List of paths that are roots in the output directory.<br><br>        "." values indicate the targets package path.<br><br>        If a file or directory being copied is in one of the listed paths or one of its subpaths,         the output directory path is the path relative to the root path instead of the path         relative to the file's workspace.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. Partial matches         on the final path segment of a root path against the corresponding segment         in the full workspace relative path of a file are not matched.<br><br>        If there are multiple root paths that match, the longest match wins.<br><br>        Defaults to [package_name()] so that the output directory path of files in the         target's package and and sub-packages are relative to the target's package and         files outside of that retain their full workspace relative paths.   | List of strings | optional | ["."] |
| <a id="copy_to_directory-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy         into the output directory.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="#copy_to_directory_lib.impl"></a>

## copy_to_directory_lib.impl

<pre>
copy_to_directory_lib.impl(<a href="#copy_to_directory_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="copy_to_directory_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


