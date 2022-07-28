<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths`, `include_srcs_patters`, `exclude_srcs_patters` and `replace_prefixes` attributes.


<a id="copy_to_directory"></a>

## copy_to_directory

<pre>
copy_to_directory(<a href="#copy_to_directory-name">name</a>, <a href="#copy_to_directory-allow_overwrites">allow_overwrites</a>, <a href="#copy_to_directory-exclude_prefixes">exclude_prefixes</a>, <a href="#copy_to_directory-exclude_srcs_patterns">exclude_srcs_patterns</a>,
                  <a href="#copy_to_directory-include_external_repositories">include_external_repositories</a>, <a href="#copy_to_directory-include_srcs_patterns">include_srcs_patterns</a>, <a href="#copy_to_directory-out">out</a>, <a href="#copy_to_directory-replace_prefixes">replace_prefixes</a>,
                  <a href="#copy_to_directory-root_paths">root_paths</a>, <a href="#copy_to_directory-srcs">srcs</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="copy_to_directory-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="copy_to_directory-allow_overwrites"></a>allow_overwrites |  If True, allow files to be overwritten if the same output file is copied to twice.<br><br>        If set, then the order of srcs matters as the last copy of a particular file will win.<br><br>        This setting has no effect on Windows where overwrites are always allowed.   | Boolean | optional | False |
| <a id="copy_to_directory-exclude_prefixes"></a>exclude_prefixes |  List of path prefixes to exclude from output directory.<br><br>        DEPRECATED: use <code>exclude_srcs_patterns</code> instead<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported but the prefix must not end with a <code>**</code> or <code>*</code> glob expression.<br><br>        See <code>glob_match</code> documentation for more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        If the output directory path for a file or directory starts with or is equal to         a path in the list then that file is not copied to the output directory.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        <code>exclude_prefixes</code> are matched on the output path after <code>root_paths</code> are considered.<br><br>        <code>exclude_prefixes</code> are matched *after* <code>include_srcs_patterns</code> and *before* <code>replace_prefixes</code> are applied.<br><br>        NB: Prefixes that nest into source directories or generated directories (TreeArtifacts) targets         are not supported since matches are performed in Starlark. To use <code>exclude_prefixes</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>.   | List of strings | optional | [] |
| <a id="copy_to_directory-exclude_srcs_patterns"></a>exclude_srcs_patterns |  List of paths (with glob support) to  exclude from output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported.<br><br>        See <code>glob_match</code> documentation for more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        If the output directory path for a file or directory starts with or is equal to         a path in the list then that file is not copied to the output directory.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        <code>exclude_srcs_patterns</code> are matched on the output path after <code>root_paths</code> are considered.<br><br>        <code>exclude_srcs_patterns</code> are matched *after* <code>include_srcs_patterns</code> and *before* <code>replace_prefixes</code> are applied.<br><br>        NB: Prefixes that nest into source directories or generated directories (TreeArtifacts) targets         are not supported since matches are performed in Starlark. To use <code>exclude_srcs_patterns</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>.   | List of strings | optional | [] |
| <a id="copy_to_directory-include_external_repositories"></a>include_external_repositories |  List of external repository names to include in the output directory.<br><br>        Files from external repositories are not copied into the output directory unless         the external repository they come from is listed here.<br><br>        When copied from an external repository, the file path in the output directory         defaults to the file's path within the external repository. The external repository         name is _not_ included in that path.<br><br>        For example, the following copies <code>@external_repo//path/to:file</code> to         <code>path/to/file</code> within the output directory.<br><br>        <pre><code>         copy_to_directory(             name = "dir",             include_external_repositories = ["external_repo"],             srcs = ["@external_repo//path/to:file"],         )         </code></pre><br><br>        Files from external repositories are subject to <code>root_paths</code>, <code>include_srcs_patterns</code>,         <code>exclude_srcs_patterns</code> and <code>replace_prefixes</code> in the same way as files form the main repository.   | List of strings | optional | [] |
| <a id="copy_to_directory-include_srcs_patterns"></a>include_srcs_patterns |  List of paths (with glob support) to  include in output directory.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported.<br><br>        See <code>glob_match</code> documentation for more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        Defaults to ["**"] which includes all sources.<br><br>        If not empty, a file is only copied to the output directory if          the output directory path for a file or directory starts with or is equal to         a path in the list.<br><br>        <code>include_srcs_patterns</code> are matched on the output path after <code>root_paths</code> are considered.<br><br>        <code>include_srcs_patterns</code> are matched *before* <code>exclude_srcs_patterns</code> and <code>replace_prefixes</code> are applied.<br><br>        NB: Prefixes that nest into source directories or generated directories (TreeArtifacts) targets         are not supported since matches are performed in Starlark. To use <code>include_srcs_patterns</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>.   | List of strings | optional | ["**"] |
| <a id="copy_to_directory-out"></a>out |  Path of the output directory, relative to this package.<br><br>        If not set, the name of the target is used.   | String | optional | "" |
| <a id="copy_to_directory-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>        If the output directory path for a file or directory starts with or is equal to         a key in the dict then the matching portion of the output directory path is         replaced with the dict value for that key.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. The final path segment         of the key can be a partial match in the corresponding segment of the output         directory path.<br><br>        <code>replace_prefixes</code> are matched on the output path after <code>root_paths</code> are considered.<br><br>        <code>replace_prefixes</code> are matched *after* <code>include_srcs_patterns</code> and <code>exclude_srcs_patterns</code> are applied.<br><br>        If there are multiple keys that match, the longest match wins.<br><br>        NB: Prefixes that nest into source directories or generated directories (TreeArtifacts) targets         are not supported since matches are performed in Starlark. To use <code>replace_prefixes</code> on files         within directories you can use the <code>make_directory_paths</code> helper to specify individual files inside         directories in <code>srcs</code>.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="copy_to_directory-root_paths"></a>root_paths |  List of paths that are roots in the output directory.<br><br>        "." values indicate the target's package path.<br><br>        Glob patterns <code>**</code>, <code>*</code> and <code>?</code> are supported but the path must not end with a <code>**</code> or <code>*</code> glob expression.<br><br>        See <code>glob_match</code> documentation for more details on how to use glob patterns:         https://github.com/aspect-build/bazel-lib/blob/main/docs/glob_match.md.<br><br>        If a file or directory being copied is in one of the listed paths or one of its subpaths,         the output directory path is the path relative to the root path instead of the path         relative to the file's workspace.<br><br>        Forward slashes (<code>/</code>) should be used as path separators. Partial matches         on the final path segment of a root path against the corresponding segment         in the full workspace relative path of a file are not matched.<br><br>        If there are multiple root paths that match, the longest match wins.<br><br>        Defaults to ["."] so that the output directory path of files in the         target's package and and sub-packages are relative to the target's package and         files outside of that retain their full workspace relative paths.   | List of strings | optional | ["."] |
| <a id="copy_to_directory-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy         into the output directory.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |


<a id="copy_to_directory_action"></a>

## copy_to_directory_action

<pre>
copy_to_directory_action(<a href="#copy_to_directory_action-ctx">ctx</a>, <a href="#copy_to_directory_action-srcs">srcs</a>, <a href="#copy_to_directory_action-dst">dst</a>, <a href="#copy_to_directory_action-additional_files">additional_files</a>, <a href="#copy_to_directory_action-root_paths">root_paths</a>,
                         <a href="#copy_to_directory_action-include_external_repositories">include_external_repositories</a>, <a href="#copy_to_directory_action-include_srcs_patterns">include_srcs_patterns</a>, <a href="#copy_to_directory_action-exclude_srcs_patterns">exclude_srcs_patterns</a>,
                         <a href="#copy_to_directory_action-exclude_prefixes">exclude_prefixes</a>, <a href="#copy_to_directory_action-replace_prefixes">replace_prefixes</a>, <a href="#copy_to_directory_action-allow_overwrites">allow_overwrites</a>, <a href="#copy_to_directory_action-is_windows">is_windows</a>)
</pre>

Helper function to copy files to a directory.

This helper is used by copy_to_directory. It is exposed as a public API so it can be used within
other rule implementations where additional_files can also be passed in.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="copy_to_directory_action-ctx"></a>ctx |  The rule context.   |  none |
| <a id="copy_to_directory_action-srcs"></a>srcs |  Files and/or directories or targets that provide DirectoryPathInfo to copy into the output directory.   |  none |
| <a id="copy_to_directory_action-dst"></a>dst |  The directory to copy to. Must be a TreeArtifact.   |  none |
| <a id="copy_to_directory_action-additional_files"></a>additional_files |  Additional files to copy that are not in the DefaultInfo or DirectoryPathInfo of srcs   |  <code>[]</code> |
| <a id="copy_to_directory_action-root_paths"></a>root_paths |  List of paths that are roots in the output directory.<br><br>See copy_to_directory rule documentation for more details.   |  <code>["."]</code> |
| <a id="copy_to_directory_action-include_external_repositories"></a>include_external_repositories |  List of external repository names to include in the output directory.<br><br>See copy_to_directory rule documentation for more details.   |  <code>[]</code> |
| <a id="copy_to_directory_action-include_srcs_patterns"></a>include_srcs_patterns |  List of paths (with glob support) to  include in output directory.<br><br>See copy_to_directory rule documentation for more details.   |  <code>["**"]</code> |
| <a id="copy_to_directory_action-exclude_srcs_patterns"></a>exclude_srcs_patterns |  List of paths (with glob support) to  exclude from output directory.<br><br>See copy_to_directory rule documentation for more details.   |  <code>[]</code> |
| <a id="copy_to_directory_action-exclude_prefixes"></a>exclude_prefixes |  List of path prefixes to exclude from output directory.   |  <code>[]</code> |
| <a id="copy_to_directory_action-replace_prefixes"></a>replace_prefixes |  Map of paths prefixes to replace in the output directory path when copying files.<br><br>See copy_to_directory rule documentation for more details.   |  <code>{}</code> |
| <a id="copy_to_directory_action-allow_overwrites"></a>allow_overwrites |  If True, allow files to be overwritten if the same output file is copied to twice.<br><br>See copy_to_directory rule documentation for more details.   |  <code>False</code> |
| <a id="copy_to_directory_action-is_windows"></a>is_windows |  If true, an cmd.exe action is created so there is no bash dependency.   |  <code>False</code> |


<a id="copy_to_directory_lib.impl"></a>

## copy_to_directory_lib.impl

<pre>
copy_to_directory_lib.impl(<a href="#copy_to_directory_lib.impl-ctx">ctx</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="copy_to_directory_lib.impl-ctx"></a>ctx |  <p align="center"> - </p>   |  none |


