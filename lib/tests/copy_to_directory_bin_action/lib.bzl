"""
Test rule to create a lib with a DefaultInfo and a OtherInfo
"""

load(":other_info.bzl", "OtherInfo")

_attrs = {
    "srcs": attr.label_list(allow_files = True),
    "others": attr.label_list(allow_files = True),
}

def _lib_impl(ctx):
    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
        OtherInfo(files = depset(ctx.files.others)),
    ]

lib = rule(
    implementation = _lib_impl,
    attrs = _attrs,
    provides = [DefaultInfo, OtherInfo],
)
