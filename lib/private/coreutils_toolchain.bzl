"Setup coreutils toolchain repositories and rules"

# Platform names follow the platform naming convention in @aspect_bazel_lib//:lib/private/repo_utils.bzl
COREUTILS_PLATFORMS = {
    "darwin_amd64": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:x86_64",
        ],
    ),
    "darwin_arm64": struct(
        compatible_with = [
            "@platforms//os:macos",
            "@platforms//cpu:aarch64",
        ],
    ),
    "linux_amd64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "linux_arm64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:aarch64",
        ],
    ),
    "windows_amd64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

# https://github.com/uutils/coreutils/releases
#
# The integrity hashes can be automatically fetched for the coreutils releases by running
# `tools/coreutils_mirror_release.sh`.
COREUTILS_VERSIONS = {
    "0.0.27": {
        "darwin_arm64": {
            "filename": "coreutils-0.0.27-aarch64-apple-darwin.tar.gz",
            "sha256": "sha256-BjAeGgJ8+sLCIwmokCOkfelCCLtnNRH49QcFnrDq8a4=",
        },
        "linux_arm64": {
            "filename": "coreutils-0.0.27-aarch64-unknown-linux-musl.tar.gz",
            "sha256": "sha256-doU+ZfTyA5I8RSwDAcsOkEI3BZXFuFwBfEbg+diS06g=",
        },
        "darwin_amd64": {
            "filename": "coreutils-0.0.27-x86_64-apple-darwin.tar.gz",
            "sha256": "sha256-1ivz4ue8/ROUYhPh22Bg2ASPgC6MKMulR52nLgZvTBo=",
        },
        "windows_amd64": {
            "filename": "coreutils-0.0.27-x86_64-pc-windows-msvc.zip",
            "sha256": "sha256-DC4H+hQX51aHoFudV39n7u217NDcNL9AiG4o4edboV0=",
        },
        "linux_amd64": {
            "filename": "coreutils-0.0.27-x86_64-unknown-linux-musl.tar.gz",
            "sha256": "sha256-tM+hJd16cCjflJyMwsCaevPYZMiBkIKZJm7/XC+760w=",
        },
    },
    "0.0.26": {
        "darwin_arm64": {
            "filename": "coreutils-0.0.26-aarch64-apple-darwin.tar.gz",
            "sha256": "sha256-/A6CNYWmvOwPW443pH+wO+VtzDFgussN1hRGuANnFOU=",
        },
        "linux_arm64": {
            "filename": "coreutils-0.0.26-aarch64-unknown-linux-musl.tar.gz",
            "sha256": "sha256-9zGLFOMDjUDbraDY/hrE5zFJ0O+QYrvx2wHk3Gw3q/A=",
        },
        "darwin_amd64": {
            # TODO: remove this version_override hack once 0.0.27 is releases and contains a darwin arm binary
            "version_override": "0.0.23",
            "filename": "coreutils-0.0.23-x86_64-apple-darwin.tar.gz",
            "sha256": "sha256-SswetVAuK/hMK1r9uBvNnKj5JpSgD0bzkbsHTxOabCo=",
        },
        "windows_amd64": {
            "filename": "coreutils-0.0.26-x86_64-pc-windows-msvc.zip",
            "sha256": "sha256-6qPkqxQZM4XBBBJ80t1uvzfZiz0gBeT/zoCdfqOO3uk=",
        },
        "linux_amd64": {
            "filename": "coreutils-0.0.26-x86_64-unknown-linux-musl.tar.gz",
            "sha256": "sha256-QpGVp3wmHqpt5Brd/bdj7pyMQNftcihOtaRI8z2uhp0=",
        },
    },
}

DEFAULT_COREUTILS_VERSION = COREUTILS_VERSIONS.keys()[0]

CoreUtilsInfo = provider(
    doc = "Provide info for executing coreutils",
    fields = {
        "bin": "Executable coreutils binary",
    },
)

def _coreutils_toolchain_impl(ctx):
    binary = ctx.file.binary

    # Make the $(COREUTILS_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "COREUTILS_BIN": binary.path,
    })
    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    coreutils_info = CoreUtilsInfo(
        bin = binary,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        coreutils_info = coreutils_info,
        template_variables = template_variables,
        default = default_info,
    )

    return [default_info, toolchain_info, template_variables]

coreutils_toolchain = rule(
    implementation = _coreutils_toolchain_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def _coreutils_toolchains_repo_impl(rctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """# @generated by @aspect_bazel_lib//lib/private:coreutils_toolchain.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@aspect_bazel_lib//lib:coreutils_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.coreutils_info,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@aspect_bazel_lib//lib:coreutils_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """# @generated by @aspect_bazel_lib//lib/private:coreutils_toolchain.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains flag.
# By default all these toolchains are registered by the coreutils_register_toolchains macro
# so you don't normally need to interact with these targets.

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])

"""

    for [platform, meta] in COREUTILS_PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:coreutils_toolchain",
    toolchain_type = "@aspect_bazel_lib//lib:coreutils_toolchain_type",
)
""".format(
            platform = platform,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

coreutils_toolchains_repo = repository_rule(
    _coreutils_toolchains_repo_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {
        "user_repository_name": attr.string(doc = "Base name for toolchains repository"),
    },
)

def _coreutils_platform_repo_impl(rctx):
    is_windows = rctx.attr.platform.startswith("windows_")
    platform = rctx.attr.platform
    filename = COREUTILS_VERSIONS[rctx.attr.version][platform]["filename"]
    version = rctx.attr.version
    if "version_override" in COREUTILS_VERSIONS[rctx.attr.version][platform]:
        version = COREUTILS_VERSIONS[rctx.attr.version][platform]["version_override"]
    url = "https://github.com/uutils/coreutils/releases/download/{}/{}".format(
        version,
        filename,
    )
    rctx.download_and_extract(
        url = url,
        stripPrefix = filename.replace(".zip", "").replace(".tar.gz", ""),
        integrity = COREUTILS_VERSIONS[rctx.attr.version][platform]["sha256"],
    )
    build_content = """# @generated by @aspect_bazel_lib//lib/private:coreutils_toolchain.bzl
load("@aspect_bazel_lib//lib/private:coreutils_toolchain.bzl", "coreutils_toolchain")
exports_files(["{0}"])
coreutils_toolchain(name = "coreutils_toolchain", binary = "{0}", visibility = ["//visibility:public"])
""".format("coreutils.exe" if is_windows else "coreutils")

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

coreutils_platform_repo = repository_rule(
    implementation = _coreutils_platform_repo_impl,
    doc = "Fetch external tools needed for coreutils toolchain",
    attrs = {
        "version": attr.string(mandatory = True, values = COREUTILS_VERSIONS.keys()),
        "platform": attr.string(mandatory = True, values = COREUTILS_PLATFORMS.keys()),
    },
)
