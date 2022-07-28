"""Copies files and directories to an output directory.

Files and directories can be arranged as needed in the output directory using
the `root_paths`, `include_srcs_patters`, `exclude_srcs_patters` and `replace_prefixes` attributes.
"""

load(
    "//lib/private:copy_to_directory.bzl",
    _copy_to_directory_action = "copy_to_directory_action",
    _copy_to_directory_lib = "copy_to_directory_lib",
)

# export the starlark library as a public API
copy_to_directory_lib = _copy_to_directory_lib
copy_to_directory_action = _copy_to_directory_action

copy_to_directory = rule(
    implementation = _copy_to_directory_lib.impl,
    provides = _copy_to_directory_lib.provides,
    attrs = _copy_to_directory_lib.attrs,
)
