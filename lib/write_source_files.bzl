"Public API for write_source_files"

load("//lib/private:write_source_files.bzl", _lib = "write_source_files_lib")
load("//lib:utils.bzl", _to_label = "to_label")
load("@bazel_skylib//rules:diff_test.bzl", _diff_test = "diff_test")
load("//lib/private:fail_with_message_test.bzl", "fail_with_message_test")

_write_source_files = rule(
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
        additional_update_targets: (Optional) List of other write_source_files targets to update in the same run
        suggested_update_target: (Optional) Label of the write_source_files target to suggest running when files are out of date
        **kwargs: Other common named parameters such as `tags` or `visibility`
    """

    out_files = files.keys()
    in_files = [files[f] for f in out_files]

    # Stamp an executable rule that writes to the out file
    _write_source_files(
        name = name,
        in_files = in_files,
        out_files = out_files,
        additional_update_targets = additional_update_targets,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        visibility = kwargs.get("visibility"),
        tags = kwargs.get("tags"),
    )

    # Fail if user passes args that would conflict with stamped out targets below
    if kwargs.pop("file1", None) != None:
        fail("file1 not a valid parameter in write_source_file")
    if kwargs.pop("file2", None) != None:
        fail("file2 not a valid parameter in write_source_file")
    if kwargs.pop("failure_message", None) != None:
        fail("failure_message not a valid parameter in write_source_file")

    for i in range(len(out_files)):
        out_file = _to_label(out_files[i])
        out_file_missing = _is_file_missing(out_file)

        name_test = "%s_%d_test" % (name, i)

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
                name = name_test,
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
                name = name_test,
                file1 = in_files[i],
                file2 = out_file,
                failure_message = message,
                **kwargs
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
