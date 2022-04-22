<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API

<a id="#get_env_var"></a>

## get_env_var

<pre>
get_env_var(<a href="#get_env_var-rctx">rctx</a>, <a href="#get_env_var-name">name</a>, <a href="#get_env_var-default">default</a>)
</pre>

Find an environment variable in system. Doesn't %-escape the value!

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="get_env_var-rctx"></a>rctx |  repository_ctx   |  none |
| <a id="get_env_var-name"></a>name |  environment variable name   |  none |
| <a id="get_env_var-default"></a>default |  default value to return if env var is not set in system   |  none |

**RETURNS**

The environment variable value or the default if it is not set


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


<a id="#os_arch_name"></a>

## os_arch_name

<pre>
os_arch_name(<a href="#os_arch_name-rctx">rctx</a>)
</pre>

Returns a normalized name of the host os and CPU architecture.

Alias archictures names are normalized:

x86_64 => amd64
aarch64 => arm64

The result can be used to generate repository names for host toolchain
repositories for toolchains that use these normalized names.

Common os & architecture pairs that are returned are,

- darwin_amd64
- darwin_arm64
- linux_amd64
- linux_arm64
- linux_s390x
- linux_ppc64le
- windows_amd64


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="os_arch_name-rctx"></a>rctx |  repository_ctx   |  none |

**RETURNS**

The normalized "<os_name>_<arch>" string of the host os and CPU architecture.


<a id="#os_name"></a>

## os_name

<pre>
os_name(<a href="#os_name-rctx">rctx</a>)
</pre>

Returns the name of the host operating system

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="os_name-rctx"></a>rctx |  repository_ctx   |  none |

**RETURNS**

The string "windows", "linux" or "darwin" that describes the host os


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


