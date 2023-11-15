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

Choosing execution requirements
-------------------------------

Copy actions can be very numerous, especially when used on third-party dependency packages.

By default, we set the `execution_requirements` of actions we spawn to be non-sandboxed and run
locally, not reading or writing to a remote cache. For the typical user this is the fastest, because
it avoids the overhead of creating a sandbox and making network calls for every file being copied.

If you use Remote Execution and Build-without-the-bytes, then you'll want the copy action to
occur on the remote machine instead, since the inputs and outputs stay in the cloud and don't need
to be brought to the local machine where Bazel runs.

Other reasons to allow copy actions to run remotely:
- Bazel prints an annoying warning "[action] uses implicit fallback from sandbox to local, which is deprecated because it is not hermetic"
- When the host and exec platforms have different architectures, toolchain resolution runs the wrong binary locally,
  see https://github.com/aspect-build/bazel-lib/issues/466

To disable our `copy_use_local_execution` flag, put this in your `.bazelrc` file:

```
# with Bazel 6.4 or greater:

# Disable default for execution_requirements of copy actions
common --@aspect_bazel_lib//lib:copy_use_local_execution=false

# with Bazel 6.3 or earlier:

# Disable default for execution_requirements of copy actions
build --@aspect_bazel_lib//lib:copy_use_local_execution=false
fetch --@aspect_bazel_lib//lib:copy_use_local_execution=false
query --@aspect_bazel_lib//lib:copy_use_local_execution=false
```
"""

load(
    "//lib/private:copy_file.bzl",
    _COPY_FILE_TOOLCHAINS = "COPY_FILE_TOOLCHAINS",
    _copy_file = "copy_file",
    _copy_file_action = "copy_file_action",
)

copy_file = _copy_file
copy_file_action = _copy_file_action
COPY_FILE_TOOLCHAINS = _COPY_FILE_TOOLCHAINS
