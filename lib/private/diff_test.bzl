# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A test rule that compares two binary files or two directories.

Similar to `bazel-skylib`'s [`diff_test`](https://github.com/bazelbuild/bazel-skylib/blob/main/rules/diff_test.bzl)
but also supports comparing directories.

The rule uses a Bash command (diff) on Linux/macOS/non-Windows, and a cmd.exe
command (fc.exe) on Windows (no Bash is required).

With `--@bazel_lib//lib:diff_test_validation`, the comparison runs as a
[validation action](https://bazel.build/extending/rules#validation_actions) instead.
"""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib:paths.bzl", "to_rlocation_path")
load("//lib:windows_utils.bzl", "BATCH_RLOCATION_FUNCTION")
load(":directory_path.bzl", "DirectoryPathInfo")

def _runfiles_path(f):
    if f.root.path:
        return f.path[len(f.root.path) + 1:]  # generated file
    else:
        return f.path  # source file

_PASSING_TEST_SH = """\
#!/usr/bin/env bash
# {name} compared its files in a validation action when it was built.
[[ -z "${{XML_OUTPUT_FILE:-}}" ]] || cat >"$XML_OUTPUT_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="{name}" tests="1" failures="0">
  <testsuite name="{name}" tests="1" failures="0" id="0">
    <testcase name="{name}" assertions="1" status="passed"></testcase>
  </testsuite>
</testsuites>
EOF
"""

def _xml_escape(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;")

def _diff_validation(ctx, is_windows, file1, file2, file1_path, file2_path, file1_exec_path, file2_exec_path, fail_msg):
    """Compares the files in a validation action, and returns a test that always passes."""
    validated = ctx.actions.declare_file(ctx.label.name + ".validated")
    if is_windows:
        script = ctx.actions.declare_file(ctx.label.name + "-validation.bat")
        template = ctx.file._diff_validation_tmpl_bat
        file1_exec_path = file1_exec_path.replace("/", "\\")
        file2_exec_path = file2_exec_path.replace("/", "\\")
        validated_path = validated.path.replace("/", "\\")
    else:
        script = ctx.actions.declare_file(ctx.label.name + "-validation.sh")
        template = ctx.file._diff_validation_tmpl_sh
        validated_path = validated.path

    ctx.actions.expand_template(
        template = template,
        output = script,
        substitutions = {
            "{fail_msg}": fail_msg,
            "{file1}": file1_path,
            "{file2}": file2_path,
            "{file1_path}": file1_exec_path,
            "{file2_path}": file2_exec_path,
            "{validated}": validated_path,
            "{diff_args}": " ".join([
                shell.quote(arg)
                for arg in ctx.attr.diff_args
            ]),
        },
        is_executable = True,
    )
    ctx.actions.run(
        executable = script,
        inputs = [file1, file2],
        outputs = [validated],
        mnemonic = "DiffTestValidation",
        progress_message = "Comparing %s and %s" % (file1_path, file2_path),
    )

    # The test's inputs don't include the compared files, so its result stays cached while they change.
    # Writing the XML report spares Bazel a separate action to generate one.
    if is_windows:
        test_bin = ctx.actions.declare_file(ctx.label.name + "-test.bat")
        ctx.actions.write(test_bin, "@echo off\r\nexit /b 0\r\n", is_executable = True)
    else:
        test_bin = ctx.actions.declare_file(ctx.label.name + "-test.sh")
        ctx.actions.write(test_bin, _PASSING_TEST_SH.format(name = _xml_escape(ctx.attr.name)), is_executable = True)

    return [
        DefaultInfo(
            executable = test_bin,
            files = depset(direct = [test_bin]),
            runfiles = ctx.runfiles(files = [test_bin]),
        ),
        OutputGroupInfo(_validation = depset([validated])),
    ]

def _diff_test_impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    file1_sub_path = ""
    if DirectoryPathInfo in ctx.attr.file1:
        file1 = ctx.attr.file1[DirectoryPathInfo].directory
        file1_path = "/".join([_runfiles_path(file1), ctx.attr.file1[DirectoryPathInfo].path])
        file1_sub_path = ctx.attr.file1[DirectoryPathInfo].path
        file1_exec_path = "/".join([file1.path, file1_sub_path])
    else:
        if len(ctx.files.file1) != 1:
            fail("file1 must be a single file or a target that provides a DirectoryPathInfo")
        file1 = ctx.files.file1[0]
        file1_path = _runfiles_path(file1)
        file1_exec_path = file1.path

    file2_sub_path = ""
    if DirectoryPathInfo in ctx.attr.file2:
        file2 = ctx.attr.file2[DirectoryPathInfo].directory
        file2_path = "/".join([_runfiles_path(file2), ctx.attr.file2[DirectoryPathInfo].path])
        file2_sub_path = ctx.attr.file2[DirectoryPathInfo].path
        file2_exec_path = "/".join([file2.path, file2_sub_path])
    else:
        if len(ctx.files.file2) != 1:
            fail("file2 must be a single file or a target that provides a DirectoryPathInfo")
        file2 = ctx.files.file2[0]
        file2_path = _runfiles_path(file2)
        file2_exec_path = file2.path

    if file1 == file2:
        msg = "diff_test comparing the same file %s" % file1
        fail(msg)

    if is_windows:
        test_suffix = "-test.bat"
        template = ctx.file._diff_test_tmpl_bat
        fail_msg = "\r\n".join(["@echo" + (" " + line if line.strip() != "" else ".") for line in ctx.attr.failure_message[:-1].splitlines()])
    else:
        test_suffix = "-test.sh"
        template = ctx.file._diff_test_tmpl_sh
        fail_msg = ctx.attr.failure_message

    if ctx.attr._validation[BuildSettingInfo].value:
        return _diff_validation(ctx, is_windows, file1, file2, file1_path, file2_path, file1_exec_path, file2_exec_path, fail_msg)

    if is_windows:
        file1_path = to_rlocation_path(ctx, file1)
        file2_path = to_rlocation_path(ctx, file2)

    test_bin = ctx.actions.declare_file(ctx.label.name + test_suffix)
    ctx.actions.expand_template(
        template = template,
        output = test_bin,
        substitutions = {
            "{BATCH_RLOCATION_FUNCTION}": "\r\n".join(BATCH_RLOCATION_FUNCTION.splitlines()),
            "{name}": ctx.attr.name,
            "{fail_msg}": fail_msg,
            "{file1}": file1_path,
            "{file2}": file2_path,
            "{file1_sub_path}": file1_sub_path,
            "{file2_sub_path}": file2_sub_path,
            "{package}": ctx.label.package,
            "{diff_args}": " ".join([
                shell.quote(arg)
                for arg in ctx.attr.diff_args
            ]),
        },
        is_executable = True,
    )

    return DefaultInfo(
        executable = test_bin,
        files = depset(direct = [test_bin]),
        runfiles = ctx.runfiles(files = [test_bin, file1, file2]),
    )

_diff_test = rule(
    attrs = {
        "failure_message": attr.string(),
        "file1": attr.label(
            allow_files = True,
            mandatory = True,
        ),
        "file2": attr.label(
            allow_files = True,
            mandatory = True,
        ),
        "diff_args": attr.string_list(),
        "_windows_constraint": attr.label(default = "@platforms//os:windows"),
        "_diff_test_tmpl_sh": attr.label(
            default = ":diff_test_tmpl.sh",
            allow_single_file = True,
        ),
        "_diff_test_tmpl_bat": attr.label(
            default = ":diff_test_tmpl.bat",
            allow_single_file = True,
        ),
        "_diff_validation_tmpl_sh": attr.label(
            default = ":diff_validation_tmpl.sh",
            allow_single_file = True,
        ),
        "_diff_validation_tmpl_bat": attr.label(
            default = ":diff_validation_tmpl.bat",
            allow_single_file = True,
        ),
        "_validation": attr.label(default = "//lib:diff_test_validation"),
    },
    test = True,
    implementation = _diff_test_impl,
)

def diff_test(name, file1, file2, diff_args = [], size = "small", **kwargs):
    """A test that compares two files.

    The test succeeds if the files' contents match.

    With `--@bazel_lib//lib:diff_test_validation`, the files are compared in a validation action
    when the test is built, and the test itself always passes. A difference then fails
    `bazel build` as well as `bazel test`, and the test's cached result survives changes to the files.

    Args:
      name: The name of the test rule.
      file1: Label of the file to compare to <code>file2</code>.
      file2: Label of the file to compare to <code>file1</code>, or a list of strings which are the lines to expect <code>file1</code> to contain.
      diff_args: Arguments to pass to the `diff` command. (Ignored on Windows)
      size: standard attribute for tests
      **kwargs: The <a href="https://docs.bazel.build/versions/main/be/common-definitions.html#common-attributes-tests">common attributes for tests</a>.
    """
    if types.is_list(file2):
        write_file2_target = name + ".file2"
        write_file(
            name = write_file2_target,
            out = write_file2_target + ".txt",
            content = file2,
        )
        file2 = write_file2_target

    _diff_test(
        name = name,
        file1 = file1,
        file2 = file2,
        size = size,
        diff_args = diff_args,
        **kwargs
    )
