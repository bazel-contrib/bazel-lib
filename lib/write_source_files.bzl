"Public API for write_source_files"

load(
    "//lib/private:write_source_file.bzl",
    _write_source_file = "write_source_file",
)

def write_source_files(
        name,
        files = {},
        executable = False,
        additional_update_targets = [],
        suggested_update_target = None,
        diff_test = True,
        **kwargs):
    """Write one or more files and/or directories to the source tree.

    By default, `diff_test` targets are generated that ensure the source tree files and/or directories to be written to
    are up to date and the rule also checks that all source tree files and/or directories to be written to exist.
    To disable the exists check and up-to-date tests set `diff_test` to `False`.

    Usage:

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

    Args:
        name: Name of the runnable target that creates or updates the source tree files and/or directories.

        files: A dict where the keys are files or directories in the source tree to write to and the values are labels
            pointing to the desired content, typically file or directory outputs of other targets.

            Destination files and directories must be within the same containing Bazel package as this target.

        executable: Whether source tree files written should be made executable.

            This applies to all source tree files written by this target. This attribute is not propagated to `additional_update_targets`.

            To set different executable permissions on different source tree files use multiple `write_source_files` targets.

        additional_update_targets: List of other `write_source_files` or `write_source_file` targets to call in the same run.

        suggested_update_target: Label of the `write_source_files` or `write_source_file` target to suggest running when files are out of date.

        diff_test: Test that the source tree files and/or directories exist and are up to date.

        **kwargs: Other common named parameters such as `tags` or `visibility`
    """

    single_update_target = len(files.keys()) == 1
    update_targets = []
    test_targets = []
    for i, pair in enumerate(files.items()):
        out_file, in_file = pair

        this_suggested_update_target = suggested_update_target
        if single_update_target:
            update_target_name = name
        else:
            update_target_name = "%s_%d" % (name, i)
            update_targets.append(update_target_name)
            if not this_suggested_update_target:
                this_suggested_update_target = name

        # Runnable target that writes to the out file to the source tree
        test_target = _write_source_file(
            name = update_target_name,
            in_file = in_file,
            out_file = out_file,
            executable = executable,
            additional_update_targets = additional_update_targets if single_update_target else [],
            suggested_update_target = this_suggested_update_target,
            diff_test = diff_test,
            **kwargs
        )

        if test_target:
            test_targets.append(test_target)

    if len(test_targets) > 0:
        native.test_suite(
            name = "%s_tests" % name,
            tests = test_targets,
            visibility = kwargs.get("visibility"),
            tags = kwargs.get("tags"),
        )

    if not single_update_target:
        _write_source_file(
            name = name,
            additional_update_targets = update_targets + additional_update_targets,
            suggested_update_target = suggested_update_target,
            diff_test = False,
            **kwargs
        )

write_source_file = _write_source_file
