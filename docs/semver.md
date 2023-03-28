<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Starlark utilties for semantic versioning

<a id="semver.parse"></a>

## semver.parse

<pre>
semver.parse(<a href="#semver.parse-version">version</a>)
</pre>

Parse a semver string into a struct containing info about the semver.

E.g.
```
sv = semver.parse("v1.2.3-alpha1+1234")

sv.major # "1"
sv.minor # "2"
sv.patch # "3"
sv.prerelease # True
sv.identifiers # "alpha1"
sv.build_metadata # "1234"
sv.v # True (whether prefixed with "v")

```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="semver.parse-version"></a>version |  Semver string   |  none |

**RETURNS**

Semver struct


<a id="semver.sort"></a>

## semver.sort

<pre>
semver.sort(<a href="#semver.sort-semvers">semvers</a>)
</pre>

Sort a list of semver structs in order of precedence.

Precedence is defined by the semver spec: https://semver.org/.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="semver.sort-semvers"></a>semvers |  List of semver structs   |  none |

**RETURNS**

List of semvers sorted in order of precedence.


<a id="semver.to_str"></a>

## semver.to_str

<pre>
semver.to_str(<a href="#semver.to_str-semver">semver</a>)
</pre>

Convert a semver struct to a string.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="semver.to_str-semver"></a>semver |  Semver struct   |  none |

**RETURNS**

The semver in string form.


