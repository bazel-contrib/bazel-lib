<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API

<a id="#glob_directories"></a>

## glob_directories

<pre>
glob_directories(<a href="#glob_directories-include">include</a>, <a href="#glob_directories-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="glob_directories-include"></a>include |  <p align="center"> - </p>   |  none |
| <a id="glob_directories-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


<a id="#is_external_label"></a>

## is_external_label

<pre>
is_external_label(<a href="#is_external_label-param">param</a>)
</pre>

Returns True if the given Label (or stringy version of a label) represents a target outside of the workspace

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="is_external_label-param"></a>param |  a string or label   |  none |

**RETURNS**

a bool


<a id="#path_to_workspace_root"></a>

## path_to_workspace_root

<pre>
path_to_workspace_root()
</pre>

 Retuns the path to the workspace root under bazel


**RETURNS**

Path to the workspace root


<a id="#propagate_well_known_tags"></a>

## propagate_well_known_tags

<pre>
propagate_well_known_tags(<a href="#propagate_well_known_tags-tags">tags</a>)
</pre>

Returns a list of tags filtered from the input set that only contains the ones that are considered "well known"

These are listed in Bazel's documentation:
https://docs.bazel.build/versions/main/test-encyclopedia.html#tag-conventions
https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="propagate_well_known_tags-tags"></a>tags |  List of tags to filter   |  <code>[]</code> |

**RETURNS**

List of tags that only contains the well known set


<a id="#to_label"></a>

## to_label

<pre>
to_label(<a href="#to_label-param">param</a>)
</pre>

Converts a string to a Label. If Label is supplied, the same label is returned.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="to_label-param"></a>param |  a string representing a label or a Label   |  none |

**RETURNS**

a Label


