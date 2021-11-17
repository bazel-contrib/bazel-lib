"Public API for copy_to_directory"

load(
    "//lib/private:copy_to_directory.bzl",
    lib = "copy_to_directory_lib",
)

_copy_to_directory = rule(
    implementation = lib.impl,
    provides = lib.provides,
    attrs = lib.attrs,
)

def copy_to_directory(name, root_paths = None, **kwargs):
    if root_paths == None:
        root_paths = [native.package_name()]
    _copy_to_directory(
        name = name,
        root_paths = root_paths,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
