"""A rule that copies a directory to another place.

The rule uses a Bash command on Linux/macOS/non-Windows, and a cmd.exe command
on Windows (no Bash is required).

NB: if you use Remote Execution and Build-without-the-bytes, then you'll want the copy action to
occur on the remote machine. You should therefore disable our `copy_use_local_execution` flag
in your `.bazelrc` file:

```
# with Bazel 6.4 or greater
common --@aspect_bazel_lib//lib:copy_use_local_execution=false

# with Bazel 6.3 or earlier:

build --@aspect_bazel_lib//lib:copy_use_local_execution=false
fetch --@aspect_bazel_lib//lib:copy_use_local_execution=false
query --@aspect_bazel_lib//lib:copy_use_local_execution=false
```
"""

load(
    "//lib/private:copy_directory.bzl",
    _copy_directory = "copy_directory",
    _copy_directory_bin_action = "copy_directory_bin_action",
)

copy_directory = _copy_directory
copy_directory_bin_action = _copy_directory_bin_action
