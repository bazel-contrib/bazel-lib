<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API

<a id="#is_darwin_os"></a>

## is_darwin_os

<pre>
is_darwin_os(<a href="#is_darwin_os-rctx">rctx</a>)
</pre>

Returns true if the host operating system is Darwin

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="is_darwin_os-rctx"></a>rctx |  <p align="center"> - </p>   |  none |


<a id="#is_linux_os"></a>

## is_linux_os

<pre>
is_linux_os(<a href="#is_linux_os-rctx">rctx</a>)
</pre>

Returns true if the host operating system is Linux

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="is_linux_os-rctx"></a>rctx |  <p align="center"> - </p>   |  none |


<a id="#is_windows_os"></a>

## is_windows_os

<pre>
is_windows_os(<a href="#is_windows_os-rctx">rctx</a>)
</pre>

Returns true if the host operating system is Windows

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="is_windows_os-rctx"></a>rctx |  <p align="center"> - </p>   |  none |


<a id="#patch"></a>

## patch

<pre>
patch(<a href="#patch-ctx">ctx</a>, <a href="#patch-patches">patches</a>, <a href="#patch-patch_cmds">patch_cmds</a>, <a href="#patch-patch_cmds_win">patch_cmds_win</a>, <a href="#patch-patch_tool">patch_tool</a>, <a href="#patch-patch_args">patch_args</a>, <a href="#patch-auth">auth</a>, <a href="#patch-patch_directory">patch_directory</a>)
</pre>

Implementation of patching an already extracted repository.

This rule is intended to be used in the implementation function of
a repository rule. If the parameters `patches`, `patch_tool`,
`patch_args`, `patch_cmds` and `patch_cmds_win` are not specified
then they are taken from `ctx.attr`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="patch-ctx"></a>ctx |  The repository context of the repository rule calling this utility function.   |  none |
| <a id="patch-patches"></a>patches |  The patch files to apply. List of strings, Labels, or paths.   |  <code>None</code> |
| <a id="patch-patch_cmds"></a>patch_cmds |  Bash commands to run for patching, passed one at a time to bash -c. List of strings   |  <code>None</code> |
| <a id="patch-patch_cmds_win"></a>patch_cmds_win |  Powershell commands to run for patching, passed one at a time to powershell /c. List of strings. If the boolean value of this parameter is false, patch_cmds will be used and this parameter will be ignored.   |  <code>None</code> |
| <a id="patch-patch_tool"></a>patch_tool |  Path of the patch tool to execute for applying patches. String.   |  <code>None</code> |
| <a id="patch-patch_args"></a>patch_args |  Arguments to pass to the patch tool. List of strings.   |  <code>None</code> |
| <a id="patch-auth"></a>auth |  An optional dict specifying authentication information for some of the URLs.   |  <code>None</code> |
| <a id="patch-patch_directory"></a>patch_directory |  Directory to apply the patches in   |  <code>None</code> |


