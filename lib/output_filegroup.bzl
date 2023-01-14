"""A rule that copies source files to the output tree.

This rule uses a Bash command (diff) on Linux/macOS/non-Windows, and a cmd.exe
command (fc.exe) on Windows (no Bash is required).

Originally authored in rules_nodejs
https://github.com/bazelbuild/rules_nodejs/blob/8b5d27400db51e7027fe95ae413eeabea4856f8e/internal/common/copy_to_bin.bzl
"""

load(
    "//lib/private:output_filegroup.bzl",
    _output_file_action = "output_file_action",
    _output_filegroup = "output_filegroup",
    _output_files_actions = "output_files_actions",
)

output_file_action = _output_file_action
output_files_actions = _output_files_actions
output_filegroup = _output_filegroup
