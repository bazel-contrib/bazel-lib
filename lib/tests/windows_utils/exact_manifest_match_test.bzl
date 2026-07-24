"Tests for exact Windows runfiles manifest matches."

load("//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//lib/private:paths.bzl", "paths")

_SUCCESS_MARKER = "WINDOWS_EXACT_MANIFEST_MATCH_OK"

def _windows_exact_manifest_match_test_impl(ctx):
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

set "test_root=%TEST_TMPDIR:/=\%\windows-exact-manifest-match"
if exist "!test_root!" rmdir /s /q "!test_root!"
mkdir "!test_root!"
set "case_launcher=!test_root!\launcher.bat"
set "case_manifest=!test_root!\MANIFEST"
copy /y "!launcher!" "!case_launcher!" >NUL
set "payload_manifest=!payload:\=/!"
> "!case_manifest!" echo {shell_script_rlocation} !payload_manifest!
>> "!case_manifest!" echo other/{shell_script_rlocation} !test_root!\suffix-collision-payload.sh

set "RUNFILES_MANIFEST_FILE=!case_manifest!"
set "RUNFILES_MANIFEST_ONLY=1"
set "RUNFILES_DIR="
set "case_output=%TEST_TMPDIR:/=\%\exact-manifest-match-output.txt"
call "!case_launcher!" > "!case_output!" 2>&1
if errorlevel 1 (
  type "!case_output!" 1>&2
  exit /b 1
)
%SYSTEMROOT%\system32\findstr.exe /c:"{success_marker}" "!case_output!" >NUL
if errorlevel 1 (
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

windows_exact_manifest_match_test = rule(
    implementation = _windows_exact_manifest_match_test_impl,
    test = True,
    toolchains = ["@bazel_tools//tools/sh:toolchain_type"],
)
