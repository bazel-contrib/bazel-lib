"Wrapper to execute BSD tar"

load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//lib/private:tar.bzl", _tar_lib = "tar_lib")

tar_rule = rule(
    implementation = _tar_lib.implementation,
    attrs = _tar_lib.attrs,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
)

# FIXME: needs docs
# buildifier: disable=function-docstring
def tar(name, mtree = None, **kwargs):
    if types.is_list(mtree):
        write_target = "_{}.mtree".format(name)
        write_file(
            name = write_target,
            out = "{}.txt".format(write_target),
            # Ensure there's a trailing newline, as bsdtar will ignore a last line without one
            content = mtree + [""],
        )
        mtree = write_target

    tar_rule(
        name = name,
        mtree = mtree,
        **kwargs
    )
