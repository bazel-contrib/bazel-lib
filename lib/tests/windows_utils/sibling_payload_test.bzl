"Tests that the Windows launcher resolves its payload without reading the manifest."

load("//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//lib/private:paths.bzl", "paths")

_SUCCESS_MARKER = "WINDOWS_SIBLING_PAYLOAD_OK"

def _windows_sibling_payload_test_impl(ctx):
    shell_script = ctx.actions.declare_file(ctx.label.name + "_payload.sh")
    ctx.actions.write(
        output = shell_script,
        content = "#!/usr/bin/env bash\necho {}\n".format(_SUCCESS_MARKER),
        is_executable = True,
    )
    launcher = create_windows_native_launcher_script(ctx, shell_script)
    launcher_rlocation = paths.to_rlocation_path(ctx, launcher)
    shell_script_rlocation = paths.to_rlocation_path(ctx, shell_script)

    test = ctx.actions.declare_file(ctx.label.name + ".bat")
    ctx.actions.write(
        output = test,
        content = "\r\n".join(r"""@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
goto :test_main

:resolve_test_runfile
set "logical_path=%~1"
set "resolved_path="
if defined RUNFILES_MANIFEST_FILE if exist "!RUNFILES_MANIFEST_FILE!" (
  set "test_manifest=!RUNFILES_MANIFEST_FILE:/=\!"
  for /F "tokens=1,* usebackq" %%i in (`%SYSTEMROOT%\system32\findstr.exe /l /c:"!logical_path! " "!test_manifest!"`) do (
    set "resolved_path=%%j"
  )
)
if not defined resolved_path if defined RUNFILES_DIR if exist "!RUNFILES_DIR!\!logical_path:/=\!" (
  set "resolved_path=!RUNFILES_DIR!\!logical_path:/=\!"
)
if not defined resolved_path exit /b 1
set "resolved_path=!resolved_path:/=\!"
set "%~2=!resolved_path!"
exit /b 0

:test_main
call :resolve_test_runfile "{launcher_rlocation}" launcher
if errorlevel 1 exit /b 1
call :resolve_test_runfile "{shell_script_rlocation}" payload
if errorlevel 1 exit /b 1

rem Stage the launcher next to its payload under a directory whose name contains
rem a space, and point the manifest at a file that does not exist.  The launcher
rem must still find its payload, proving it resolves the sibling directly rather
rem than going through findstr -- which is what keeps it working when the
rem manifest path exceeds MAX_PATH or the .bat is invoked via an 8.3 alias.
set "test_root=%TEST_TMPDIR:/=\%\windows-sibling-payload"
if exist "!test_root!" rmdir /s /q "!test_root!"
mkdir "!test_root!"
set "spaced_dir=!test_root!\dir with spaces"
mkdir "!spaced_dir!"
for %%f in ("!launcher!") do set "launcher_name=%%~nxf"
for %%f in ("!payload!") do set "payload_name=%%~nxf"
copy /y "!launcher!" "!spaced_dir!\!launcher_name!" >NUL
copy /y "!payload!" "!spaced_dir!\!payload_name!" >NUL
set "case_manifest=!test_root!\MANIFEST"
> "!case_manifest!" echo {shell_script_rlocation} !test_root!/does-not-exist.sh

set "RUNFILES_MANIFEST_FILE=!case_manifest!"
set "RUNFILES_MANIFEST_ONLY=1"
set "RUNFILES_DIR="
set "case_output=%TEST_TMPDIR:/=\%\sibling-payload-output.txt"
call "!spaced_dir!\!launcher_name!" > "!case_output!" 2>&1
if errorlevel 1 (
  echo>&2 FAIL: launcher exited non-zero resolving a sibling payload under a spaced path.
  type "!case_output!" 1>&2
  exit /b 1
)
%SYSTEMROOT%\system32\findstr.exe /c:"{success_marker}" "!case_output!" >NUL
if errorlevel 1 (
  echo>&2 FAIL: launcher did not run its sibling payload.
  type "!case_output!" 1>&2
  exit /b 1
)
exit /b 0
""".format(
            launcher_rlocation = launcher_rlocation,
            shell_script_rlocation = shell_script_rlocation,
            success_marker = _SUCCESS_MARKER,
        ).splitlines()),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = test,
        runfiles = ctx.runfiles(files = [launcher, shell_script]),
    )]

windows_sibling_payload_test = rule(
    implementation = _windows_sibling_payload_test_impl,
    test = True,
    toolchains = ["@bazel_tools//tools/sh:toolchain_type"],
)
