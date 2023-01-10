"""A rule that copies a directory to another place.

The rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command
on Windows (no Bash is required).
"""

load(
    "//lib/private:copy_directory.bzl",
    _copy_directory = "copy_directory",
    _copy_directory_action = "copy_directory_action",
    _copy_directory_bin_action = "copy_directory_bin_action",
)

copy_directory = _copy_directory
copy_directory_action = _copy_directory_action
copy_directory_bin_action = _copy_directory_bin_action
