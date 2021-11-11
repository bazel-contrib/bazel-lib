<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for expanding variables

<a id="#expand_template"></a>

## expand_template

<pre>
expand_template(<a href="#expand_template-name">name</a>, <a href="#expand_template-data">data</a>, <a href="#expand_template-is_executable">is_executable</a>, <a href="#expand_template-out">out</a>, <a href="#expand_template-substitutions">substitutions</a>, <a href="#expand_template-template">template</a>)
</pre>

Template expansion
    
This performs a simple search over the template file for the keys in substitutions,
and replaces them with the corresponding values.

Values may also use location templates as documented in [expand_locations](#expand_locations)
as well as [configuration variables] such as `$(BINDIR)`, `$(TARGET_CPU)`, and `$(COMPILATION_MODE)`.

[configuration variables]: https://docs.bazel.build/versions/main/skylark/lib/ctx.html#var


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="expand_template-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="expand_template-data"></a>data |  List of targets for additional lookup information.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="expand_template-is_executable"></a>is_executable |  Whether to mark the output file as executable.   | Boolean | optional | False |
| <a id="expand_template-out"></a>out |  Where to write the expanded file.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="expand_template-substitutions"></a>substitutions |  Mapping of strings to substitutions.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |
| <a id="expand_template-template"></a>template |  The template file to expand.   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |


<a id="#expand_locations"></a>

## expand_locations

<pre>
expand_locations(<a href="#expand_locations-ctx">ctx</a>, <a href="#expand_locations-input">input</a>, <a href="#expand_locations-targets">targets</a>)
</pre>

Expand location templates.

Expands all `$(execpath ...)`, `$(rootpath ...)` and legacy `$(location ...)` templates in the
given string by replacing with the expanded path. Expansion only works for labels that point to direct dependencies
of this rule or that are explicitly listed in the optional argument targets.

See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables.

Use `$(rootpath)` and `$(rootpaths)` to expand labels to the runfiles path that a built binary can use
to find its dependencies. This path is of the format:
- `./file`
- `path/to/file`
- `../external_repo/path/to/file`

Use `$(execpath)` and `$(execpaths)` to expand labels to the execroot (where Bazel runs build actions).
This is of the format:
- `./file`
- `path/to/file`
- `external/external_repo/path/to/file`
- `<bin_dir>/path/to/file`
- `<bin_dir>/external/external_repo/path/to/file`

The legacy `$(location)` and `$(locations)` expansions are deprecated as they return the runfiles manifest path of the
format `repo/path/to/file` which behave differently than the built-in `$(location)` expansion in args of *_binary
and *_test rules which returns the rootpath.
See https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-binaries.

The legacy `$(location)` and `$(locations)` expansion also differs from how the builtin `ctx.expand_location()` expansions
of `$(location)` and `$(locations)` behave as that function returns either the execpath or rootpath depending on the context.
See https://docs.bazel.build/versions/main/be/make-variables.html#predefined_label_variables.

The behavior of `$(location)` and `$(locations)` expansion will be fixed in a future major release to match the
to default Bazel behavior and return the same path as `ctx.expand_location()` returns for these.

The recommended approach is to now use `$(rootpath)` where you previously used $(location). See the docstrings
of `nodejs_binary` or `params_file` for examples of how to use `$(rootpath)` in `templated_args` and `args` respectively.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="expand_locations-ctx"></a>ctx |  context   |  none |
| <a id="expand_locations-input"></a>input |  String to be expanded   |  none |
| <a id="expand_locations-targets"></a>targets |  List of targets for additional lookup information.   |  <code>[]</code> |

**RETURNS**

The expanded path or the original path


<a id="#expand_variables"></a>

## expand_variables

<pre>
expand_variables(<a href="#expand_variables-ctx">ctx</a>, <a href="#expand_variables-s">s</a>, <a href="#expand_variables-outs">outs</a>, <a href="#expand_variables-output_dir">output_dir</a>, <a href="#expand_variables-attribute_name">attribute_name</a>)
</pre>

Expand make variables and substitute like genrule does.

This function is the same as ctx.expand_make_variables with the additional
genrule-like substitutions of:

  - `$@`: The output file if it is a single file. Else triggers a build error.
  - `$(@D)`: The output directory. If there is only one file name in outs,
           this expands to the directory containing that file. If there are multiple files,
           this instead expands to the package's root directory in the bin tree,
           even if all generated files belong to the same subdirectory!
  - `$(RULEDIR)`: The output directory of the rule, that is, the directory
    corresponding to the name of the package containing the rule under the bin tree.

See https://docs.bazel.build/versions/main/be/general.html#genrule.cmd and
https://docs.bazel.build/versions/main/be/make-variables.html#predefined_genrule_variables
for more information of how these special variables are expanded.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="expand_variables-ctx"></a>ctx |  starlark rule context   |  none |
| <a id="expand_variables-s"></a>s |  expression to expand   |  none |
| <a id="expand_variables-outs"></a>outs |  declared outputs of the rule, for expanding references to outputs   |  <code>[]</code> |
| <a id="expand_variables-output_dir"></a>output_dir |  whether the rule is expected to output a directory (TreeArtifact)   |  <code>False</code> |
| <a id="expand_variables-attribute_name"></a>attribute_name |  name of the attribute containing the expression   |  <code>"args"</code> |

**RETURNS**

`s` with the variables expanded


