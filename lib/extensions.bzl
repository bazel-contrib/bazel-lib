"Module extensions for use with bzlmod"

load(
    "@aspect_bazel_lib//lib:repositories.bzl",
    "register_copy_directory_toolchains",
    "register_copy_to_directory_toolchains",
    "register_jq_toolchains",
    "register_yq_toolchains",
)

def _toolchain_extension(_):
    register_yq_toolchains(register = False)
    register_jq_toolchains(register = False)
    register_copy_directory_toolchains(register = False)
    register_copy_to_directory_toolchains(register = False)

# TODO: some way for users to control repo name/version of the tools installed
ext = module_extension(
    implementation = _toolchain_extension,
)
