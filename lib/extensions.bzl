"Module extensions for use with bzlmod"

load(
    "@aspect_bazel_lib//lib:repositories.bzl",
    "register_copy_to_directory_toolchains",
    "register_jq_toolchains",
    "register_yq_toolchains",
)
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _toolchain_extension(_):
    register_yq_toolchains(register = False)
    register_jq_toolchains(register = False)
    register_copy_to_directory_toolchains(register = False)

# TODO: some way for users to control repo name/version of the tools installed
ext = module_extension(
    implementation = _toolchain_extension,
)

def _http_extension(mctx):
    for mod in mctx.modules:
        for attr in mod.tags.http_archive:
            http_archive(
                name = attr.name,
                build_file_content = attr.build_file_content,
                sha256 = attr.sha256,
                strip_prefix = attr.strip_prefix,
                urls = attr.urls,
            )

# Extension that can declare http repository rules, until there's a better way:
# https://github.com/bazelbuild/bazel/issues/17141
http = module_extension(
    implementation = _http_extension,
    tag_classes = {
        "http_archive": tag_class(attrs = {
            "name": attr.string(),
            "url": attr.string(),
            "urls": attr.string_list(),
            "sha256": attr.string(),
            "integrity": attr.string(),
            "netrc": attr.string(),
            "auth_patterns": attr.string_dict(),
            "canonical_id": attr.string(),
            "strip_prefix": attr.string(),
            "add_prefix": attr.string(),
            "type": attr.string(),
            "patches": attr.label_list(),
            "remote_patches": attr.string_dict(),
            "remote_patch_strip": attr.int(),
            "patch_tool": attr.string(),
            "patch_args": attr.string_list(),
            "patch_cmds": attr.string_list(),
            "patch_cmds_win": attr.string_list(),
            "build_file": attr.label(),
            "build_file_content": attr.string(),
            "workspace_file": attr.label(),
            "workspace_file_content": attr.string(),
        }),
        # TODO: http_file and http_jar
    },
)
