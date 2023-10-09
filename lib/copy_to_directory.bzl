"""Copy files and directories to an output directory.

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
    "//lib/private:copy_to_directory.bzl",
    _copy_to_directory_bin_action = "copy_to_directory_bin_action",
    _copy_to_directory_lib = "copy_to_directory_lib",
)

# export the starlark library as a public API
copy_to_directory_lib = _copy_to_directory_lib
copy_to_directory_bin_action = _copy_to_directory_bin_action

copy_to_directory = rule(
    doc = _copy_to_directory_lib.doc,
    implementation = _copy_to_directory_lib.impl,
    provides = _copy_to_directory_lib.provides,
    attrs = _copy_to_directory_lib.attrs,
    toolchains = ["@aspect_bazel_lib//lib:copy_to_directory_toolchain_type"],
)
