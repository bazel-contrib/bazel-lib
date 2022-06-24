"Public API for write_source_files"

load(
    "//lib/private:write_source_file.bzl",
    _write_source_file = "write_source_file",
)

def write_source_files(
        name,
        files = {},
        additional_update_targets = [],
        suggested_update_target = None,
        diff_test = True,
        **kwargs):
    """Write to one or more files or folders in the source tree. Stamp out tests that ensure the sources exist and are up to date.

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

    A test will fail if the source file doesn't exist or if it's out of date with instructions on how to create/update it.

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

    When a file is out of date, you can leave a suggestion to run a target further up in the tree by specifying `suggested_update_target`. E.g.,

    ```starlark
    write_source_files(
        name = "write_foo",
        files = {
            "foo.json": ":generated-foo",
        },
        suggested_update_target = "//:write_all"
    )
    ```

    A test failure from foo.json being out of date will yield the following message:

    ```
    //a/b:c:foo.json is out of date. To update this and other generated files, run:

        bazel run //:write_all

    To update *only* this file, run:

        bazel run //a/b/c:write_foo
    ```

    If you have many sources that you want to update as a group, we recommend wrapping write_source_files in a macro that defaults `suggested_update_target` to the umbrella update target.
    
    NOTE: If you run formatters or linters on your codebase, it is advised that you exclude/ignore the outputs of this rule from those formatters/linters so as to avoid causing collisions and failing tests.

    Args:
        name: Name of the executable target that creates or updates the source file
        files: A dict where the keys are source files or folders to write to and the values are labels pointing to the desired content.
            Sources must be within the same bazel package as the target.
        additional_update_targets: (Optional) List of other write_source_file or other executable updater targets to call in the same run
        suggested_update_target: (Optional) Label of the write_source_file target to suggest running when files are out of date
        diff_test: (Optional) Generate a test target to check that the source file(s) exist and are up to date with the generated files(s).
        **kwargs: Other common named parameters such as `tags` or `visibility`
    """

    single_update_target = len(files.keys()) == 1
    update_targets = []
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
        _write_source_file(
            name = update_target_name,
            in_file = in_file,
            out_file = out_file,
            additional_update_targets = additional_update_targets if single_update_target else [],
            suggested_update_target = this_suggested_update_target,
            diff_test = diff_test,
            **kwargs
        )

    if not single_update_target:
        _write_source_file(
            name = name,
            additional_update_targets = update_targets + additional_update_targets,
            suggested_update_target = suggested_update_target,
            diff_test = False,
            **kwargs
        )
