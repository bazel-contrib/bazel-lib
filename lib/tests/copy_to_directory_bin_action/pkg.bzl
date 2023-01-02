"""
Test rule to create a pkg with DefaultInfo and OtherInfo files
"""

load("@aspect_bazel_lib//lib/private:copy_to_directory.bzl", "copy_to_directory_bin_action")
load(":other_info.bzl", "OtherInfo")

_attrs = {
    "srcs": attr.label_list(allow_files = True),
    "out": attr.string(mandatory = True),
    "_tool": attr.label(
        executable = True,
        cfg = "exec",
        default = "//tools/copy_to_directory",
    ),
}

def _pkg_impl(ctx):
    dst = ctx.actions.declare_directory(ctx.attr.out)

    additional_files_depsets = []

    # include files from OtherInfo of srcs
    for src in ctx.attr.srcs:
        if OtherInfo in src:
            additional_files_depsets.append(src[OtherInfo].files)

    copy_to_directory_bin_action(
        ctx,
        name = ctx.attr.name,
        files = ctx.files.srcs + depset(transitive = additional_files_depsets).to_list(),
        dst = dst,
        copy_to_directory_bin = ctx.executable._tool,
        verbose = True,
    )

    return [
        DefaultInfo(files = depset([dst])),
    ]

pkg = rule(
    implementation = _pkg_impl,
    attrs = _attrs,
    provides = [DefaultInfo],
)
