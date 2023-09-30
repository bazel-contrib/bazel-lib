"Wrapper to execute BSD tar"

load("//lib/private:tar.bzl", _tar_lib = "tar_lib")

tar_rule = rule(
    implementation = _tar_lib.implementation,
    attrs = _tar_lib.attrs,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
)

def tar(name, **kwargs):
    tar_rule(
        name = name,
        **kwargs
    )
