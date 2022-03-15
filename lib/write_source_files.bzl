"Public API for write_source_files"

load(
    "//lib/private:write_source_file.bzl",
    _lib = "write_source_file_lib",
)
load("//lib:utils.bzl", _to_label = "to_label")
load("//lib/private:diff_test.bzl", _diff_test = "diff_test")
load("//lib/private:fail_with_message_test.bzl", "fail_with_message_test")

_write_source_file = rule(
    attrs = _lib.attrs,
    implementation = _lib.implementation,
    executable = True,
)

def write_source_files(name, files = {}, additional_update_targets = [], suggested_update_target = None, **kwargs):
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

    Args:
        name: Name of the executable target that creates or updates the source file
        files: A dict where the keys are source files or folders to write to and the values are labels pointing to the desired content.
            Sources must be within the same bazel package as the target.
        additional_update_targets: (Optional) List of other write_source_file or other executable updater targets to call in the same run
        suggested_update_target: (Optional) Label of the write_source_file target to suggest running when files are out of date
        **kwargs: Other common named parameters such as `tags` or `visibility`
    """

    single_update_target = len(files.keys()) == 1
    update_targets = []
    for i, pair in enumerate(files.items()):
        out_file, in_file = pair

        in_file = _to_label(in_file)
        out_file = _to_label(out_file)

        if single_update_target:
            update_target_name = name
        else:
            update_target_name = "%s_%d" % (name, i)
            update_targets.append(update_target_name)

        # Runnable target that writes to the out file to the source tree
        _write_source_file(
            name = update_target_name,
            in_file = in_file,
            out_file = out_file,
            additional_update_targets = additional_update_targets if single_update_target else [],
            is_windows = select({
                "@bazel_tools//src/conditions:host_windows": True,
                "//conditions:default": False,
            }),
            visibility = kwargs.get("visibility"),
            tags = kwargs.get("tags"),
        )

        out_file_missing = _is_file_missing(out_file)

        if single_update_target:
            test_target_name = "%s_test" % name
        else:
            test_target_name = "%s_%d_test" % (name, i)

        if out_file_missing:
            if suggested_update_target == None:
                message = """

%s does not exist. To create & update this file, run:

    bazel run //%s:%s

""" % (out_file, native.package_name(), name)
            else:
                message = """

%s does not exist. To create & update this and other generated files, run:

    bazel run %s

To create an update *only* this file, run:

    bazel run //%s:%s

""" % (out_file, _to_label(suggested_update_target), native.package_name(), name)

            # Stamp out a test that fails with a helpful message when the source file doesn't exist.
            # Note that we cannot simply call fail() here since it will fail during the analysis
            # phase and prevent the user from calling bazel run //update/the:file.
            fail_with_message_test(
                name = test_target_name,
                message = message,
                visibility = kwargs.get("visibility"),
                tags = kwargs.get("tags"),
            )
        else:
            if suggested_update_target == None:
                message = """

%s is out of date. To update this file, run:

    bazel run //%s:%s

""" % (out_file, native.package_name(), name)
            else:
                message = """

%s is out of date. To update this and other generated files, run:

    bazel run %s

To update *only* this file, run:

    bazel run //%s:%s

""" % (out_file, _to_label(suggested_update_target), native.package_name(), name)

            # Stamp out a diff test the check that the source file is up to date
            _diff_test(
                name = test_target_name,
                file1 = in_file,
                file2 = out_file,
                failure_message = message,
                **kwargs
            )

    if not single_update_target:
        _write_source_file(
            name = name,
            additional_update_targets = update_targets + additional_update_targets,
            is_windows = select({
                "@bazel_tools//src/conditions:host_windows": True,
                "//conditions:default": False,
            }),
            visibility = kwargs.get("visibility"),
            tags = kwargs.get("tags"),
        )

def _is_file_missing(label):
    """Check if a file is missing by passing its relative path through a glob()

    Args
        label: the file's label
    """
    file_abs = "%s/%s" % (label.package, label.name)
    file_rel = file_abs[len(native.package_name()) + 1:]
    file_glob = native.glob([file_rel], exclude_directories = 0)
    return len(file_glob) == 0
