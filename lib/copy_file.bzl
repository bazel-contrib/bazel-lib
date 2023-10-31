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

# LOCAL MODIFICATIONS
# this has a PR patched in on top of the original
# https://github.com/bazelbuild/bazel-skylib/blob/7b859037a673db6f606661323e74c5d4751595e6/rules/private/copy_file_private.bzl
# https://github.com/bazelbuild/bazel-skylib/pull/324

"""A rule that copies a file to another place.

native.genrule() is sometimes used to copy files (often wishing to rename them).
The 'copy_file' rule does this with a simpler interface than genrule.

The rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command
on Windows (no Bash is required).

This fork of bazel-skylib's copy_file adds DirectoryPathInfo support and allows multiple
copy_file in the same package.
"""

load(
    "//lib/private:copy_file.bzl",
    _copy_file = "copy_file",
    _copy_file_action = "copy_file_action",
)

copy_file = _copy_file
copy_file_action = _copy_file_action
