"""
Test rule to create a pkg with DefaultInfo and OtherInfo files
"""

load("@aspect_bazel_lib//lib/private:copy_to_directory.bzl", "copy_to_directory_bin_action")
load("//lib:paths.bzl", "relative_file")
load("//lib:utils.bzl", "is_bazel_6_or_greater")
load(":other_info.bzl", "OtherInfo")

_attrs = {
    "srcs": attr.label_list(allow_files = True),
    "out": attr.string(mandatory = True),
    "use_declare_symlink": attr.bool(mandatory = True),
    "_tool": attr.label(
        executable = True,
        cfg = "exec",
        default = "//tools/copy_to_directory",
    ),
}

# buildifier: disable=function-docstring
def _make_symlink(ctx, symlink_path, target_file):
    if ctx.attr.use_declare_symlink:
        symlink = ctx.actions.declare_symlink(symlink_path)
        ctx.actions.symlink(
            output = symlink,
            target_path = relative_file(target_file.path, symlink.path),
        )
        return symlink
    else:
        if is_bazel_6_or_greater() and target_file.is_directory:
            symlink = ctx.actions.declare_directory(symlink_path)
        else:
            symlink = ctx.actions.declare_file(symlink_path)
        ctx.actions.symlink(
            output = symlink,
            target_file = target_file,
        )
        return symlink

def _pkg_impl(ctx):
    dst = ctx.actions.declare_directory(ctx.attr.out)

    additional_files_depsets = []

    # include files from OtherInfo of srcs
    for src in ctx.attr.srcs:
        if OtherInfo in src:
            additional_files_depsets.append(src[OtherInfo].files)

    # test that the copy action can handle symlinks to files and directories
    symlinks = []
    for i, f in enumerate(ctx.files.srcs):
        symlinks.append(_make_symlink(ctx, "{}_symlink_{}".format(ctx.attr.name, i), f))

    copy_to_directory_bin_action(
        ctx,
        name = ctx.attr.name,
        files = ctx.files.srcs + symlinks + depset(transitive = additional_files_depsets).to_list(),
        dst = dst,
        copy_to_directory_bin = ctx.executable._tool,
        hardlink = "auto",
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
