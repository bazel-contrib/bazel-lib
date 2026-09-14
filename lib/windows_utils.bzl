# Copyright 2017 The Bazel Authors. All rights reserved.
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

"Helpers for rules running on windows"

load("//lib/private:paths.bzl", "paths")

# cmd.exe function for looking up runfiles.
# Equivalent of the BASH_RLOCATION_FUNCTION in paths.bzl.
# Use this to write actions that don't require bash.
# Originally by @meteorcloudy in
# https://github.com/bazel-contrib/rules_nodejs/commit/f06553a
BATCH_RLOCATION_FUNCTION = r"""
rem Usage of rlocation function:
rem        call :rlocation <runfile_path> <abs_path>
rem        The rlocation function maps the given <runfile_path> to its absolute
rem        path and stores the result in a variable named <abs_path>.
rem        This function fails if the <runfile_path> cannot be found in either
rem        the runfiles manifest or directory.
:: Start of rlocation
goto :rlocation_end
:rlocation
if "%~2" equ "" (
  echo>&2 ERROR: Expected two arguments for rlocation function.
  exit 1
)
set "MF="
set "RF="
if defined RUNFILES_MANIFEST_FILE if exist "!RUNFILES_MANIFEST_FILE!" (
  set "MF=!RUNFILES_MANIFEST_FILE:/=\!"
)
if not defined MF if defined RUNFILES_DIR if exist "!RUNFILES_DIR!\" (
  set "RF=!RUNFILES_DIR:/=\!"
)
if not defined MF if not defined RF if exist "%~f0.runfiles\MANIFEST" (
  set "MF=%~f0.runfiles\MANIFEST"
)
if not defined MF if not defined RF if exist "%~f0.runfiles_manifest" (
  set "MF=%~f0.runfiles_manifest"
)
if not defined MF if not defined RF if exist "%~f0.runfiles\" (
  set "RF=%~f0.runfiles"
)
if defined MF (
  set "RUNFILES_DIR="
  set "RUNFILES_MANIFEST_FILE=!MF:\=/!"
  set "RUNFILES_MANIFEST_ONLY=1"
  set "runfile_path=%~1"
  set "abs_path="
  for /F "tokens=2* usebackq" %%i in (`%SYSTEMROOT%\system32\findstr.exe /b /l /c:"!runfile_path! " "!MF!"`) do (
    set "abs_path=%%i"
  )
  if "!abs_path!" equ "" (
    echo>&2 ERROR: !runfile_path! not found in runfiles manifest
    exit 1
  )
  set "%~2=!abs_path!"
  exit /b 0
)
if defined RF (
  set "RUNFILES_MANIFEST_FILE="
  set "RUNFILES_DIR=!RF:\=/!"
  set "RUNFILES_MANIFEST_ONLY="
  set "runfile_path=%~1"
  set "abs_path=!RF!\!runfile_path:/=\!"
  if not exist "!abs_path!" (
    echo>&2 ERROR: !runfile_path! not found under runfiles directory !RF!
    exit 1
  )
  set "%~2=!abs_path!"
  exit /b 0
)
echo>&2 ERROR: Cannot find a runfiles manifest or directory.
exit 1
:rlocation_end
:: End of rlocation
"""

def create_windows_native_launcher_script(ctx, shell_script):
    """Create a Windows Batch file to launch the given shell script.

    The rule should specify @bazel_tools//tools/sh:toolchain_type as a required toolchain.

    Args:
        ctx: Rule context
        shell_script: The bash launcher script

    Returns:
        A windows launcher script
    """
    name = shell_script.basename
    if name.endswith(".sh"):
        name = name[:-3]
    win_launcher = ctx.actions.declare_file(name + ".bat", sibling = shell_script)
    ctx.actions.write(
        output = win_launcher,
        content = "\r\n".join(r"""@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
{rlocation_function}
call :rlocation "{sh_script}" run_script
set "run_script=!run_script:\=/!"
for %%a in ("{bash_bin}") do set "bash_bin_dir=%%~dpa"
set PATH=%bash_bin_dir%;%PATH%
set args=%*
rem Escape \ and * in args before passing it with double quote
if defined args (
  set args=!args:\=\\\\!
  set args=!args:"=\"!
)
"{bash_bin}" -c "!run_script! !args!"
""".format(
            bash_bin = ctx.toolchains["@bazel_tools//tools/sh:toolchain_type"].path,
            sh_script = paths.to_rlocation_path(ctx, shell_script),
            rlocation_function = BATCH_RLOCATION_FUNCTION,
        ).splitlines()),
        is_executable = True,
    )
    return win_launcher
