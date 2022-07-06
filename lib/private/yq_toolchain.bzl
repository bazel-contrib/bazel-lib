"Setup yq toolchain repositories and rules"

load(":repo_utils.bzl", "repo_utils")

# Platform names follow the platform naming convention in @aspect_bazel_lib//:lib/private/repo_utils.bzl
YQ_PLATFORMS = {
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
    "linux_s390x": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:s390x",
        ],
    ),
    "linux_ppc64le": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:ppc",
        ],
    ),
    "windows_amd64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

DEFAULT_YQ_VERSION = "4.25.2"

# https://github.com/mikefarah/yq/releases
#
# The integrity hashes can be automatically fetched for the latest yq release by running
# `tools/yq_mirror_release.sh`. To calculate for a specific release run
# `tools/yq_mirror_release.sh <release_version>`
#
# Alternatively, you can compute them manually by running
# `shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64`
YQ_VERSIONS = {
    "4.25.2": {
        "darwin_amd64": "sha384-JOSKdcN5JoSfryJBDFzTSk21uFVNw+bWdLHTErwIyaUOAZZV9LISzlmsYiQoPfo3",
        "darwin_arm64": "sha384-COVD0Ko3vQUmSS/SS17VrpA4gTaxuyszgPfE9P8vNKLlB+65I7HznstHg/iElxrk",
        "linux_amd64": "sha384-uK7+qPUYBO1bnKUNYKqKuGpfTKsRktfptGATlV14AFb5hiVp6vcWvDyTRSfiZn5f",
        "linux_arm64": "sha384-2SwY2OtotYhupSEeUSHRKTMbUoIhUyIt7QgujH3UyaQ/9AoXWNZ3h05OAdWL5WbL",
        "linux_s390x": "sha384-AXZe1USYMi0mg5ylHnU8OGqQQZcMDETD/bLWG0BKytSBhZ0Xkkhn9r90fJYM4xVS",
        "linux_ppc64le": "sha384-N6UXrIzrpPy6zojzI8J7AFP5z3UAe9KU8WLuUKe8WrttuD1Fl3YTwvo/OM2+5NTt",
        "windows_amd64": "sha384-wD0GpKHTLQIWWNJv43ts+l2rIdAiyYYtb3upncdIOLLydFcWxB39+thcQ8aSdaW+",
    },
    "4.24.5": {
        "darwin_amd64": "sha384-Y6Utm9NAX7q69apRHLAU6oNYk5Kn5b6LUccBolbTm2CXXYye8pabeFPsaREFIHbw",
        "darwin_arm64": "sha384-d6+hFiZrsUeqnXJufnvadTi0BL/sfbd6K7LnJyLVDy31C0isjyHipVqlibKYbFSu",
        "linux_amd64": "sha384-FEWzb66XTTiMfz5wA/hCs/n0N+PVj4lXzKX8ZIUXnM3JTlFlBvA9X59elqqEJUPq",
        "linux_arm64": "sha384-u8H3RxTssXKr1lEylydi1tzXKKsoax7aDXi4R/JF8irZ7RTwCqU/ogMj30B0Xo01",
        "linux_s390x": "sha384-ccipOj8IBVDb6ZxBYDyRDVvfOTHRSD4nGuMbikrDrigGdYyI/iVb+R8lb6kdLarb",
        "linux_ppc64le": "sha384-HWzKwuNx+uZI/8KXSNFVg+drCZiZU/17hIl8gG+b+UyLMAFZ/sOB/nu7yzEOdzvH",
        "windows_amd64": "sha384-6T42wIkqXZ8OCetIeMjTlTIVQDwlRpTXj8pi+SrGzU4r5waq3SwIYSrDqUxMD43j",
    },
    "4.24.4": {
        "darwin_amd64": "sha384-H5JnUD7c0jpbOvvN1pGz12XFi3XrX+ism4iGnH9wv37i+qdkD2AdTbTe4MIFtMR+",
        "darwin_arm64": "sha384-9B85+dFTGRmMWWP2M+PVOkl8CtAb/HV4+XNGC0OBfdBvdJU85FyiTb12XGEgNjFp",
        "linux_amd64": "sha384-y8vr5fWIqSvJhMoHwldoVPOJpAfLi4iHcnhfTcm/nuJAxGAJmI2MiBbk3t7lQNHC",
        "linux_arm64": "sha384-nxvFzxOVNtbt1lQZshkUnM6SHQnXKkzWKEw4TzU9HOms6mUJnYbYXc0x0LwPkpQK",
        "linux_s390x": "sha384-525bIc8L80mIMVH+PmNDi4vBP4AfvBw/736ISW0F7+7zowSYOUK+EN/REo31kNdN",
        "linux_ppc64le": "sha384-Sm3PniOqhRIlYaVBZOwncKRpPDLhiuHNCvVWUW9ihnAQM3woXvhb5iNfbws0Rz+G",
        "windows_amd64": "sha384-f8jkaz3oRaDcn8jiXupeDO665t6d2tTnFuU0bKwLWszXSz8r29My/USG+UoO9hOr",
    },
}

YqInfo = provider(
    doc = "Provide info for executing yq",
    fields = {
        "bin": "Executable yq binary",
    },
)

def _yq_toolchain_impl(ctx):
    binary = ctx.attr.bin.files.to_list()[0]

    # Make the $(YQ_BIN) variable available in places like genrules.
    # See https://docs.bazel.build/versions/main/be/make-variables.html#custom_variables
    template_variables = platform_common.TemplateVariableInfo({
        "YQ_BIN": binary.path,
    })
    default_info = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    yq_info = YqInfo(
        bin = binary,
    )

    # Export all the providers inside our ToolchainInfo
    # so the resolved_toolchain rule can grab and re-export them.
    toolchain_info = platform_common.ToolchainInfo(
        yqinfo = yq_info,
        template_variables = template_variables,
        default = default_info,
    )

    return [default_info, toolchain_info, template_variables]

yq_toolchain = rule(
    implementation = _yq_toolchain_impl,
    attrs = {
        "bin": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
)

def _yq_toolchains_repo_impl(rctx):
    # Expose a concrete toolchain which is the result of Bazel resolving the toolchain
    # for the execution or target platform.
    # Workaround for https://github.com/bazelbuild/bazel/issues/14009
    starlark_content = """# @generated by @aspect_bazel_lib//lib/private:yq_toolchain.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@aspect_bazel_lib//lib:yq_toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.yqinfo,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@aspect_bazel_lib//lib:yq_toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
"""
    rctx.file("defs.bzl", starlark_content)

    build_content = """# @generated by @aspect_bazel_lib//lib/private:yq_toolchain.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains flag.
# By default all these toolchains are registered by the yq_register_toolchains macro
# so you don't normally need to interact with these targets.

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])

"""

    for [platform, meta] in YQ_PLATFORMS.items():
        build_content += """
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:yq_toolchain",
    toolchain_type = "@aspect_bazel_lib//lib:yq_toolchain_type",
)
""".format(
            platform = platform,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

yq_toolchains_repo = repository_rule(
    _yq_toolchains_repo_impl,
    doc = """Creates a repository with toolchain definitions for all known platforms
     which can be registered or selected.""",
    attrs = {
        "user_repository_name": attr.string(doc = "Base name for toolchains repository"),
    },
)

def _yq_platform_repo_impl(rctx):
    is_windows = rctx.attr.platform.startswith("windows_")
    meta = YQ_PLATFORMS[rctx.attr.platform]
    release_platform = meta.release_platform if hasattr(meta, "release_platform") else rctx.attr.platform

    #https://github.com/mikefarah/yq/releases/download/v4.24.4/yq_linux_386
    url = "https://github.com/mikefarah/yq/releases/download/v{0}/yq_{1}{2}".format(
        rctx.attr.version,
        release_platform,
        ".exe" if is_windows else "",
    )

    rctx.download(
        url = url,
        output = "yq.exe" if is_windows else "yq",
        executable = True,
        integrity = YQ_VERSIONS[rctx.attr.version][release_platform],
    )
    build_content = """# @generated by @aspect_bazel_lib//lib/private:yq_toolchain.bzl
load("@aspect_bazel_lib//lib/private:yq_toolchain.bzl", "yq_toolchain")
exports_files(["{0}"])
yq_toolchain(name = "yq_toolchain", bin = "{0}", visibility = ["//visibility:public"])
""".format("yq.exe" if is_windows else "yq")

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

yq_platform_repo = repository_rule(
    implementation = _yq_platform_repo_impl,
    doc = "Fetch external tools needed for yq toolchain",
    attrs = {
        "version": attr.string(mandatory = True, values = YQ_VERSIONS.keys()),
        "platform": attr.string(mandatory = True, values = YQ_PLATFORMS.keys()),
    },
)

def _yq_host_alias_repo(rctx):
    ext = ".exe" if repo_utils.is_windows(rctx) else ""

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", """# @generated by @aspect_bazel_lib//lib/private:yq_toolchain.bzl
package(default_visibility = ["//visibility:public"])
exports_files(["yq{ext}"])
""".format(
        ext = ext,
    ))

    rctx.symlink("../{name}_{platform}/yq{ext}".format(
        name = rctx.attr.name,
        platform = repo_utils.platform(rctx),
        ext = ext,
    ), "yq{ext}".format(ext = ext))

yq_host_alias_repo = repository_rule(
    _yq_host_alias_repo,
    doc = """Creates a repository with a shorter name meant for the host platform, which contains
    a BUILD.bazel file that exports symlinks to the host platform's binaries
    """,
)
