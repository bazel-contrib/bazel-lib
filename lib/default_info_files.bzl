"""A rule that provides file(s) from a given target's DefaultInfo
"""

load(
    "//lib/private:default_info_files.bzl",
    _default_info_files = "default_info_files",
    _make_default_info_files = "make_default_info_files",
)

default_info_files = _default_info_files
make_default_info_files = _make_default_info_files
