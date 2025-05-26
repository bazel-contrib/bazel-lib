"""A test rule that checks the executable permission on a file or directory."""

load(":directory_path.bzl", "DirectoryPathInfo")

def _runfiles_path(f):
    if f.root.path:
        return f.path[len(f.root.path) + 1:]  # generated file
    else:
        return f.path  # source file

def _executable_test_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    if DirectoryPathInfo in ctx.attr.file:
        file = ctx.attr.file1[DirectoryPathInfo].directory
        file_path = "/".join([_runfiles_path(file), ctx.attr.file[DirectoryPathInfo].path])
    else:
        if len(ctx.files.file) != 1:
            fail("file must be a single file or a target that provides a DirectoryPathInfo")
        file = ctx.files.file[0]
        file_path = _runfiles_path(file)

    if is_windows:
        test_suffix = "-test.bat"
        template = ctx.file._executable_test_tmpl_bat
    else:
        test_suffix = "-test.sh"
        template = ctx.file._executable_test_tmpl_sh

    test_bin = ctx.actions.declare_file(ctx.label.name + test_suffix)
    ctx.actions.expand_template(
        template = template,
        output = test_bin,
        substitutions = {
            "{name}": ctx.attr.name,
            "{fail_msg}": ctx.attr.failure_message,
            "{file}": file_path,
            "{executable}": "true" if ctx.attr.executable else "",
            "{build_file_path}": ctx.build_file_path,
        },
        is_executable = True,
    )

    return DefaultInfo(
        executable = test_bin,
        files = depset(direct = [test_bin]),
        runfiles = ctx.runfiles(files = [test_bin, file]),
    )

_executable_test = rule(
    attrs = {
        "failure_message": attr.string(),
        "file": attr.label(
            allow_files = True,
            mandatory = True,
        ),
        "executable": attr.bool(
            mandatory = True,
        ),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
        "_executable_test_tmpl_sh": attr.label(
            default = ":executable_test_tmpl.sh",
            allow_single_file = True,
        ),
        "_executable_test_tmpl_bat": attr.label(
            default = ":executable_test_tmpl.bat",
            allow_single_file = True,
        ),
    },
    test = True,
    implementation = _executable_test_impl,
)

def executable_test(name, file, executable, size = "small", **kwargs):
    """A test that checks the executable permission on a file or directory.

    The test succeeds if the executable permission matches <code>executable</code>.

    On Windows, the test always succeeds.

    Args:
      name: The name of the test rule.
      file: Label of the file to check.
      executable: Boolean; whether the file should be executable.
      size: standard attribute for tests
      **kwargs: The <a href="https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-tests">common attributes for tests</a>.
    """
    _executable_test(
        name = name,
        file = file,
        executable = executable,
        size = size,
        **kwargs
    )
