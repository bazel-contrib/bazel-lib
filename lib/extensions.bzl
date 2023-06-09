"Module extensions for use with bzlmod"

load(
    "@aspect_bazel_lib//lib:repositories.bzl",
    "register_copy_directory_toolchains",
    "register_copy_to_directory_toolchains",
    "register_coreutils_toolchains",
    "register_expand_template_toolchains",
    "register_jq_toolchains",
    "register_yq_toolchains",
)
load("//lib/private:host_repo.bzl", "host_repo")

def _toolchain_extension(mctx):
    register_copy_directory_toolchains(register = False)
    register_copy_to_directory_toolchains(register = False)
    register_jq_toolchains(register = False)
    register_yq_toolchains(register = False)
    register_coreutils_toolchains(register = False)
    register_expand_template_toolchains(register = False)

    create_host_repo = False
    for module in mctx.modules:
        if len(module.tags.host) > 0:
            create_host_repo = True

    if create_host_repo:
        host_repo(name = "aspect_bazel_lib_host")

# TODO: some way for users to control repo name/version of the tools installed
ext = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {"host": tag_class(attrs = {})},
)
