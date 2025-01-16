"Provide access to a BSD tar"

BSDTAR_PLATFORMS = {
    "darwin_amd64": struct(
        compatible_with = [
            "@platforms//os:osx",
            "@platforms//cpu:x86_64",
        ],
    ),
    "darwin_arm64": struct(
        compatible_with = [
            "@platforms//os:osx",
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
        release_platform = "win64",
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

BSDTAR_PREBUILT = {
    "darwin_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_darwin_amd64",
        "8a7a526045b4f91cc750639039a23b30a17698afe9c7459b244b6a4902289dee",
    ),
    "darwin_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_darwin_arm64",
        "dcb1da3d6945e703a9e1a6b7a2c8b9098e14600643cc26d5c7670b78ccc9b215",
    ),
    "linux_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_linux_amd64",
        "91d1e47ccd0e99ec0cfdf0334725c0be6904eafd40d5b01b7482c063f246d83c",
    ),
    "linux_arm64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_linux_arm64",
        "2bb6b5b2cb6b9b9eda0d8ab7cb1bd5c013e33a65470cba89b22efcabc497885b",
    ),
    "windows_amd64": (
        "https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.7.5-2/tar_windows_x86_64.exe",
        "1cb376b18dfaa81a4d0a1048119830e505ce3b319fe0cfb2ebae929543995157",
    ),
}

def _bsdtar_binary_repo(rctx):
    (url, sha256) = BSDTAR_PREBUILT[rctx.attr.platform]
    binary = "tar.exe" if rctx.attr.platform.startswith("windows") else "tar"
    rctx.download(
        url = url,
        output = binary,
        executable = True,
        sha256 = sha256,
    )

    rctx.file("BUILD.bazel", """\
# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl

load("@aspect_bazel_lib//lib/private:tar_toolchain.bzl", "tar_toolchain")

package(default_visibility = ["//visibility:public"])

tar_toolchain(name = "bsdtar_toolchain", binary = "{}")
""".format(binary))

bsdtar_binary_repo = repository_rule(
    implementation = _bsdtar_binary_repo,
    attrs = {
        "platform": attr.string(mandatory = True, values = BSDTAR_PLATFORMS.keys()),
    },
)

TarInfo = provider(
    doc = "Provide info for executing BSD tar",
    fields = {
        "binary": "bsdtar executable",
    },
)

def _tar_toolchain_impl(ctx):
    binary = ctx.executable.binary

    # Make the $(BSDTAR_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "BSDTAR_BIN": binary.path,
    })

    default_info = DefaultInfo(
        files = depset(ctx.files.binary + ctx.files.files),
    )
    tarinfo = TarInfo(
        binary = binary,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        tarinfo = tarinfo,
        template_variables = template_variables,
        default = default_info,
    )

    return [toolchain_info, template_variables, default_info]

tar_toolchain = rule(
    implementation = _tar_toolchain_impl,
    attrs = {
        "binary": attr.label(
            doc = "a command to find on the system path",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "files": attr.label_list(allow_files = True),
    },
)

def _tar_toolchains_repo_impl(rctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """\
# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.tarinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """# @generated by @aspect_bazel_lib//lib/private:tar_toolchain.bzl
load(":defs.bzl", "resolved_toolchain")
load("@platforms//host:constraints.bzl", "HOST_CONSTRAINTS")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])"""

    for [platform, meta] in BSDTAR_PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:bsdtar_toolchain",
    toolchain_type = "@aspect_bazel_lib//lib:tar_toolchain_type",
)
""".format(
            platform = platform,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    rctx.file("BUILD.bazel", build_content)

tar_toolchains_repo = repository_rule(
    _tar_toolchains_repo_impl,
    doc = """Creates a repository that exposes a tar_toolchain_type target.""",
    attrs = {
        "user_repository_name": attr.string(doc = "Base name for toolchains repository"),
    },
)
