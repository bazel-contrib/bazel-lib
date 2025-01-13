<!-- Generated with Stardoc: http://skydoc.bazel.build -->

write_source_files provides a workaround for the restriction that `bazel build` cannot write to the source tree.

Read more about the philosophy of writing to the source tree: <https://blog.aspect.build/bazel-can-write-to-the-source-folder>

## Usage

```starlark
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")

write_source_files(
    name = "write_foobar",
    files = {
        "foobar.json": "//some/generated:file",
    },
)
```

To update the source file, run:

```bash
bazel run //:write_foobar
```

The generated `diff_test` will fail if the file is out of date and print out instructions on
how to update it.

If the file does not exist, Bazel will fail at analysis time and print out instructions on
how to create it.

You can declare a tree of generated source file targets:

```starlark
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")

write_source_files(
    name = "write_all",
    additional_update_targets = [
        # Other write_source_files targets to run when this target is run
        "//a/b/c:write_foo",
        "//a/b:write_bar",
    ]
)
```

And update them with a single run:

```bash
bazel run //:write_all
```

When a file is out of date, you can leave a suggestion to run a target further up in the tree by specifying `suggested_update_target`.
For example,

```starlark
write_source_files(
    name = "write_foo",
    files = {
        "foo.json": ":generated-foo",
    },
    suggested_update_target = "//:write_all"
)
```

A test failure from `foo.json` being out of date will yield the following message:

```
//a/b:c:foo.json is out of date. To update this and other generated files, run:

    bazel run //:write_all

To update *only* this file, run:

    bazel run //a/b/c:write_foo
```

If you have many `write_source_files` targets that you want to update as a group, we recommend wrapping
`write_source_files` in a macro that defaults `suggested_update_target` to the umbrella update target.

NOTE: If you run formatters or linters on your codebase, it is advised that you exclude/ignore the outputs of this
    rule from those formatters/linters so as to avoid causing collisions and failing tests.

<a id="WriteSourceFileInfo"></a>

## WriteSourceFileInfo

<pre>
WriteSourceFileInfo(<a href="#WriteSourceFileInfo-executable">executable</a>)
</pre>

Provider for write_source_file targets

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="WriteSourceFileInfo-executable"></a>executable |  Executable that updates the source files    |


<a id="write_source_file"></a>

## write_source_file

<pre>
write_source_file(<a href="#write_source_file-name">name</a>, <a href="#write_source_file-in_file">in_file</a>, <a href="#write_source_file-out_file">out_file</a>, <a href="#write_source_file-executable">executable</a>, <a href="#write_source_file-additional_update_targets">additional_update_targets</a>,
                  <a href="#write_source_file-suggested_update_target">suggested_update_target</a>, <a href="#write_source_file-diff_test">diff_test</a>, <a href="#write_source_file-check_that_out_file_exists">check_that_out_file_exists</a>, <a href="#write_source_file-kwargs">kwargs</a>)
</pre>

Write a file or directory to the source tree.

By default, a `diff_test` target ("{name}_test") is generated that ensure the source tree file or directory to be written to
is up to date and the rule also checks that the source tree file or directory to be written to exists.
To disable the exists check and up-to-date test set `diff_test` to `False`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="write_source_file-name"></a>name |  Name of the runnable target that creates or updates the source tree file or directory.   |  none |
| <a id="write_source_file-in_file"></a>in_file |  File or directory to use as the desired content to write to `out_file`.<br><br>This is typically a file or directory output of another target. If `in_file` is a directory then entire directory contents are copied.   |  `None` |
| <a id="write_source_file-out_file"></a>out_file |  The file or directory to write to in the source tree.<br><br>The output file or directory must be within the same containing Bazel package as this target if `check_that_out_file_exists` is `True`. See `check_that_out_file_exists` docstring for more info.   |  `None` |
| <a id="write_source_file-executable"></a>executable |  Whether source tree file or files within the source tree directory written should be made executable.   |  `False` |
| <a id="write_source_file-additional_update_targets"></a>additional_update_targets |  List of other `write_source_files` or `write_source_file` targets to call in the same run.   |  `[]` |
| <a id="write_source_file-suggested_update_target"></a>suggested_update_target |  Label of the `write_source_files` or `write_source_file` target to suggest running when files are out of date.   |  `None` |
| <a id="write_source_file-diff_test"></a>diff_test |  Test that the source tree file or directory exist and is up to date.   |  `True` |
| <a id="write_source_file-check_that_out_file_exists"></a>check_that_out_file_exists |  Test that the output file exists and print a helpful error message if it doesn't.<br><br>If `True`, the output file or directory must be in the same containing Bazel package as the target since the underlying mechanism for this check is limited to files in the same Bazel package.   |  `True` |
| <a id="write_source_file-kwargs"></a>kwargs |  Other common named parameters such as `tags` or `visibility`   |  none |

**RETURNS**

Name of the generated test target if requested, otherwise None.


<a id="write_source_files"></a>

## write_source_files

<pre>
write_source_files(<a href="#write_source_files-name">name</a>, <a href="#write_source_files-files">files</a>, <a href="#write_source_files-executable">executable</a>, <a href="#write_source_files-additional_update_targets">additional_update_targets</a>, <a href="#write_source_files-suggested_update_target">suggested_update_target</a>,
                   <a href="#write_source_files-diff_test">diff_test</a>, <a href="#write_source_files-check_that_out_file_exists">check_that_out_file_exists</a>, <a href="#write_source_files-kwargs">kwargs</a>)
</pre>

Write one or more files and/or directories to the source tree.

By default, `diff_test` targets are generated that ensure the source tree files and/or directories to be written to
are up to date and the rule also checks that all source tree files and/or directories to be written to exist.
To disable the exists check and up-to-date tests set `diff_test` to `False`.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="write_source_files-name"></a>name |  Name of the runnable target that creates or updates the source tree files and/or directories.   |  none |
| <a id="write_source_files-files"></a>files |  A dict where the keys are files or directories in the source tree to write to and the values are labels pointing to the desired content, typically file or directory outputs of other targets.<br><br>Destination files and directories must be within the same containing Bazel package as this target if `check_that_out_file_exists` is True. See `check_that_out_file_exists` docstring for more info.   |  `{}` |
| <a id="write_source_files-executable"></a>executable |  Whether source tree files written should be made executable.<br><br>This applies to all source tree files written by this target. This attribute is not propagated to `additional_update_targets`.<br><br>To set different executable permissions on different source tree files use multiple `write_source_files` targets.   |  `False` |
| <a id="write_source_files-additional_update_targets"></a>additional_update_targets |  List of other `write_source_files` or `write_source_file` targets to call in the same run.   |  `[]` |
| <a id="write_source_files-suggested_update_target"></a>suggested_update_target |  Label of the `write_source_files` or `write_source_file` target to suggest running when files are out of date.   |  `None` |
| <a id="write_source_files-diff_test"></a>diff_test |  Test that the source tree files and/or directories exist and are up to date.   |  `True` |
| <a id="write_source_files-check_that_out_file_exists"></a>check_that_out_file_exists |  Test that each output file exists and print a helpful error message if it doesn't.<br><br>If `True`, destination files and directories must be in the same containing Bazel package as the target since the underlying mechanism for this check is limited to files in the same Bazel package.   |  `True` |
| <a id="write_source_files-kwargs"></a>kwargs |  Other common named parameters such as `tags` or `visibility`   |  none |


