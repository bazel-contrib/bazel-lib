"Tests for Windows launcher runfiles lookup."

load("//lib:paths.bzl", "BASH_RLOCATION_FUNCTION")
load("//lib:windows_utils.bzl", "create_windows_native_launcher_script")
load("//lib/private:paths.bzl", "paths")

_SUCCESS_MARKER = "WINDOWS_LAUNCHER_RUNFILES_OK"
_DOWNSTREAM_MARKER = "WINDOWS_LAUNCHER_DOWNSTREAM_RLOCATION_OK"

_SCENARIOS = {
    "explicit_manifest": r"""
set "case_manifest=!test_root!\explicit.MANIFEST"
set "case_runfiles_dir=!test_root!\explicit.runfiles"
call :copy_runtime_runfiles "!case_runfiles_dir!"
if errorlevel 1 exit /b 1
> "!case_runfiles_dir!\{shell_script_windows}" echo echo WRONG_RUNFILES_SOURCE
> "!case_runfiles_dir!\{downstream_windows}" echo WRONG_RUNFILES_SOURCE
call :write_manifest "!case_manifest!"
set "RUNFILES_MANIFEST_FILE=!case_manifest!"
set "RUNFILES_DIR=!case_runfiles_dir!"
set "RUNFILES_MANIFEST_ONLY="
""",
    "explicit_directory": r"""
set "case_runfiles_dir=!test_root!\explicit.runfiles"
call :copy_runtime_runfiles "!case_runfiles_dir!"
if errorlevel 1 exit /b 1
> "!case_launcher!.runfiles_manifest" echo {shell_script_rlocation} !test_root!\stale-sibling-payload.sh
mkdir "!case_launcher!.runfiles"
> "!case_launcher!.runfiles\MANIFEST" echo {shell_script_rlocation} !test_root!\stale-nested-payload.sh
set "RUNFILES_MANIFEST_FILE=!test_root!\missing.MANIFEST"
set "RUNFILES_DIR=!case_runfiles_dir!"
set "RUNFILES_MANIFEST_ONLY=1"
""",
    "adjacent_nested_manifest": r"""
mkdir "!case_launcher!.runfiles"
call :write_manifest "!case_launcher!.runfiles\MANIFEST"
> "!case_launcher!.runfiles_manifest" echo {shell_script_rlocation} !test_root!\stale-sibling-payload.sh
set "RUNFILES_MANIFEST_FILE="
set "RUNFILES_DIR="
set "RUNFILES_MANIFEST_ONLY="
""",
    "adjacent_sibling_manifest": r"""
call :write_manifest "!case_launcher!.runfiles_manifest"
set "RUNFILES_MANIFEST_FILE="
set "RUNFILES_DIR="
set "RUNFILES_MANIFEST_ONLY="
""",
    "adjacent_directory": r"""
set "case_runfiles_dir=!case_launcher!.runfiles"
call :copy_runtime_runfiles "!case_runfiles_dir!"
if errorlevel 1 exit /b 1
set "RUNFILES_MANIFEST_FILE="
set "RUNFILES_DIR="
set "RUNFILES_MANIFEST_ONLY=1"
""",
}

def _windows_directory_runfiles_test_impl(ctx):
    downstream = ctx.actions.declare_file(ctx.label.name + "_downstream.txt")
    ctx.actions.write(
        output = downstream,
        content = _DOWNSTREAM_MARKER + "\n",
    )

    shell_script = ctx.actions.declare_file(ctx.label.name + "_payload.sh")
    ctx.actions.write(
        output = shell_script,
        content = "\n".join([
            "#!/usr/bin/env bash",
            BASH_RLOCATION_FUNCTION,
            'downstream="$(rlocation "{}")"'.format(paths.to_rlocation_path(ctx, downstream)),
            'grep -Fqx "{}" "$downstream"'.format(_DOWNSTREAM_MARKER),
            "echo {}".format(_SUCCESS_MARKER),
            "",
        ]),
        is_executable = True,
    )
    launcher = create_windows_native_launcher_script(ctx, shell_script)

    launcher_rlocation = paths.to_rlocation_path(ctx, launcher)
    downstream_rlocation = paths.to_rlocation_path(ctx, downstream)
    runfiles_bash_rlocation = paths.to_rlocation_path(ctx, ctx.file._runfiles_bash)
    shell_script_rlocation = paths.to_rlocation_path(ctx, shell_script)
    substitutions = {
        "downstream_rlocation": downstream_rlocation,
        "downstream_windows": downstream_rlocation.replace("/", "\\"),
        "launcher_rlocation": launcher_rlocation,
        "runfiles_bash_rlocation": runfiles_bash_rlocation,
        "runfiles_bash_windows": runfiles_bash_rlocation.replace("/", "\\"),
        "shell_script_rlocation": shell_script_rlocation,
        "shell_script_windows": shell_script_rlocation.replace("/", "\\"),
        "success_marker": _SUCCESS_MARKER,
    }
    scenario_setup = _SCENARIOS[ctx.attr.scenario].format(**substitutions)

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
if not defined resolved_path (
  echo>&2 ERROR: Test setup could not resolve !logical_path!
  exit /b 1
)
set "resolved_path=!resolved_path:/=\!"
set "%~2=!resolved_path!"
exit /b 0

:copy_runfile
set "runfile_source=%~1"
set "runfile_destination=%~2"
for %%i in ("!runfile_destination!") do if not exist "%%~dpi" mkdir "%%~dpi"
copy /y "!runfile_source!" "!runfile_destination!" >NUL
if errorlevel 1 (
  echo>&2 ERROR: Could not copy !runfile_source! to !runfile_destination!
  exit /b 1
)
exit /b 0

:copy_runtime_runfiles
set "runtime_runfiles_dir=%~1"
call :copy_runfile "!payload!" "!runtime_runfiles_dir!\{shell_script_windows}"
if errorlevel 1 exit /b 1
call :copy_runfile "!downstream!" "!runtime_runfiles_dir!\{downstream_windows}"
if errorlevel 1 exit /b 1
call :copy_runfile "!runfiles_bash!" "!runtime_runfiles_dir!\{runfiles_bash_windows}"
exit /b !ERRORLEVEL!

:write_manifest
set "manifest_destination=%~1"
> "!manifest_destination!" echo {shell_script_rlocation} !payload!
>> "!manifest_destination!" echo {downstream_rlocation} !downstream!
>> "!manifest_destination!" echo {runfiles_bash_rlocation} !runfiles_bash!
exit /b 0

:test_main
call :resolve_test_runfile "{launcher_rlocation}" launcher
if errorlevel 1 exit /b 1
call :resolve_test_runfile "{shell_script_rlocation}" payload
if errorlevel 1 exit /b 1
call :resolve_test_runfile "{downstream_rlocation}" downstream
if errorlevel 1 exit /b 1
call :resolve_test_runfile "{runfiles_bash_rlocation}" runfiles_bash
if errorlevel 1 exit /b 1

set "test_root=%TEST_TMPDIR:/=\%\windows-launcher-{scenario}"
if exist "!test_root!" rmdir /s /q "!test_root!"
mkdir "!test_root!"
set "case_launcher=!test_root!\launcher.bat"
copy /y "!launcher!" "!case_launcher!" >NUL
if errorlevel 1 exit /b 1

{scenario_setup}

set "case_output=%TEST_TMPDIR:/=\%\{scenario}-output.txt"
call "!case_launcher!" > "!case_output!" 2>&1
if errorlevel 1 (
  echo>&2 ERROR: Launcher failed for {scenario}
  type "!case_output!" 1>&2
  exit /b 1
)
%SYSTEMROOT%\system32\findstr.exe /c:"{success_marker}" "!case_output!" >NUL
if errorlevel 1 (
  echo>&2 ERROR: Launcher did not execute the runfile for {scenario}
  type "!case_output!" 1>&2
  exit /b 1
)
exit /b 0
""".format(
            scenario = ctx.attr.scenario,
            scenario_setup = scenario_setup,
            **substitutions
        ).splitlines()),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = test,
        runfiles = ctx.runfiles(files = [ctx.file._runfiles_bash, downstream, launcher, shell_script]),
    )]

windows_directory_runfiles_test = rule(
    attrs = {
        "scenario": attr.string(
            mandatory = True,
            values = _SCENARIOS.keys(),
        ),
        "_runfiles_bash": attr.label(
            allow_single_file = True,
            default = Label("@bazel_tools//tools/bash/runfiles:runfiles"),
        ),
    },
    implementation = _windows_directory_runfiles_test_impl,
    test = True,
    toolchains = ["@bazel_tools//tools/sh:toolchain_type"],
)
