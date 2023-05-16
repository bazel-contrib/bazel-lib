<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Macros for loading dependencies and registering toolchains

<a id="aspect_bazel_lib_dependencies"></a>

## aspect_bazel_lib_dependencies

<pre>
aspect_bazel_lib_dependencies(<a href="#aspect_bazel_lib_dependencies-override_local_config_platform">override_local_config_platform</a>)
</pre>

Load dependencies required by aspect rules

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="aspect_bazel_lib_dependencies-override_local_config_platform"></a>override_local_config_platform |  override the @local_config_platform repository with one that adds stardoc support for loading constraints.bzl.<br><br>Should be set in repositories that load @aspect_bazel_lib copy actions and also generate stardoc.   |  <code>False</code> |


<a id="register_copy_directory_toolchains"></a>

## register_copy_directory_toolchains

<pre>
register_copy_directory_toolchains(<a href="#register_copy_directory_toolchains-name">name</a>, <a href="#register_copy_directory_toolchains-register">register</a>)
</pre>

Registers copy_directory toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_copy_directory_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"copy_directory"</code> |
| <a id="register_copy_directory_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


<a id="register_copy_to_directory_toolchains"></a>

## register_copy_to_directory_toolchains

<pre>
register_copy_to_directory_toolchains(<a href="#register_copy_to_directory_toolchains-name">name</a>, <a href="#register_copy_to_directory_toolchains-register">register</a>)
</pre>

Registers copy_to_directory toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_copy_to_directory_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"copy_to_directory"</code> |
| <a id="register_copy_to_directory_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


<a id="register_coreutils_toolchains"></a>

## register_coreutils_toolchains

<pre>
register_coreutils_toolchains(<a href="#register_coreutils_toolchains-name">name</a>, <a href="#register_coreutils_toolchains-version">version</a>, <a href="#register_coreutils_toolchains-register">register</a>)
</pre>

Registers coreutils toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_coreutils_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"coreutils"</code> |
| <a id="register_coreutils_toolchains-version"></a>version |  the version of coreutils to execute (see https://github.com/uutils/coreutils/releases)   |  <code>"0.0.16"</code> |
| <a id="register_coreutils_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


<a id="register_expand_template_toolchains"></a>

## register_expand_template_toolchains

<pre>
register_expand_template_toolchains(<a href="#register_expand_template_toolchains-name">name</a>, <a href="#register_expand_template_toolchains-register">register</a>)
</pre>

Registers expand_template toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_expand_template_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"expand_template"</code> |
| <a id="register_expand_template_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


<a id="register_jq_toolchains"></a>

## register_jq_toolchains

<pre>
register_jq_toolchains(<a href="#register_jq_toolchains-name">name</a>, <a href="#register_jq_toolchains-version">version</a>, <a href="#register_jq_toolchains-register">register</a>)
</pre>

Registers jq toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_jq_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"jq"</code> |
| <a id="register_jq_toolchains-version"></a>version |  the version of jq to execute (see https://github.com/stedolan/jq/releases)   |  <code>"1.6"</code> |
| <a id="register_jq_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


<a id="register_yq_toolchains"></a>

## register_yq_toolchains

<pre>
register_yq_toolchains(<a href="#register_yq_toolchains-name">name</a>, <a href="#register_yq_toolchains-version">version</a>, <a href="#register_yq_toolchains-register">register</a>)
</pre>

Registers yq toolchain and repositories

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="register_yq_toolchains-name"></a>name |  override the prefix for the generated toolchain repositories   |  <code>"yq"</code> |
| <a id="register_yq_toolchains-version"></a>version |  the version of yq to execute (see https://github.com/mikefarah/yq/releases)   |  <code>"4.25.2"</code> |
| <a id="register_yq_toolchains-register"></a>register |  whether to call through to native.register_toolchains. Should be True for WORKSPACE users, but false when used under bzlmod extension   |  <code>True</code> |


