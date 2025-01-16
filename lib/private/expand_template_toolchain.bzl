"Setup expand_template toolchain repositories and rules"

# https://github.com/bazel-contrib/bazel-lib/releases
load("//tools:integrity.bzl", "RELEASED_BINARY_INTEGRITY")
load("//tools:version.bzl", "VERSION")

# Platform names follow the platform naming convention in @aspect_bazel_lib//:lib/private/repo_utils.bzl
EXPAND_TEMPLATE_PLATFORMS = {
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
    "freebsd_amd64": struct(
        compatible_with = [
            "@platforms//os:freebsd",
            "@platforms//cpu:x86_64",
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

ExpandTemplateInfo = provider(
    doc = "Provide info for executing expand_template",
    fields = {
        "bin": "Executable expand_template binary",
    },
)

def _expand_template_toolchain_impl(ctx):
    binary = ctx.executable.bin

    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    expand_template_info = ExpandTemplateInfo(
        bin = binary,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        expand_template_info = expand_template_info,
        default = default_info,
    )

    return [default_info, toolchain_info]

expand_template_toolchain = rule(
    implementation = _expand_template_toolchain_impl,
    attrs = {
        "bin": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

def _expand_template_toolchains_repo_impl(rctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """# @generated by @aspect_bazel_lib//lib/private:expand_template_toolchain.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@aspect_bazel_lib//lib:expand_template_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.expand_template_info,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@aspect_bazel_lib//lib:expand_template_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """# @generated by @aspect_bazel_lib//lib/private:expand_template_toolchain.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains flag.
# By default all these toolchains are registered by the expand_template_register_toolchains macro
# so you don't normally need to interact with these targets.

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])

"""

    for [platform, meta] in EXPAND_TEMPLATE_PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:expand_template_toolchain",
    toolchain_type = "@aspect_bazel_lib//lib:expand_template_toolchain_type",
)
""".format(
            platform = platform,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

expand_template_toolchains_repo = repository_rule(
    _expand_template_toolchains_repo_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {
        "user_repository_name": attr.string(doc = "Base name for toolchains repository"),
    },
)

def _expand_template_platform_repo_impl(rctx):
    is_windows = rctx.attr.platform.startswith("windows_")
    meta = EXPAND_TEMPLATE_PLATFORMS[rctx.attr.platform]
    release_platform = meta.release_platform if hasattr(meta, "release_platform") else rctx.attr.platform
    release_file = "expand_template-{}{}".format(release_platform, ".exe" if is_windows else "")

    # https://github.com/bazel-contrib/bazel-lib/releases/download/v1.19.0/expand_template-linux_amd64
    url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v{}/{}".format(
        VERSION,
        release_file,
    )

    rctx.download(
        url = url,
        output = "expand_template.exe" if is_windows else "expand_template",
        executable = True,
        sha256 = RELEASED_BINARY_INTEGRITY[release_file],
    )
    build_content = """# @generated by @aspect_bazel_lib//lib/private:expand_template_toolchain.bzl
load("@aspect_bazel_lib//lib/private:expand_template_toolchain.bzl", "expand_template_toolchain")
exports_files(["{0}"])
expand_template_toolchain(name = "expand_template_toolchain", bin = "{0}", visibility = ["//visibility:public"])
""".format("expand_template.exe" if is_windows else "expand_template")

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

expand_template_platform_repo = repository_rule(
    implementation = _expand_template_platform_repo_impl,
    doc = "Fetch external tools needed for expand_template toolchain",
    attrs = {
        "platform": attr.string(mandatory = True, values = EXPAND_TEMPLATE_PLATFORMS.keys()),
    },
)
