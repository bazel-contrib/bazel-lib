"Macros for loading dependencies and registering toolchains"

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//lib/private:jq_toolchain.bzl", "JQ_PLATFORMS", "jq_platform_repo", "jq_toolchains_repo")

def aspect_bazel_lib_dependencies():
    "Load dependencies required by aspect rules"
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
        ],
    )

def register_jq_toolchains(version, name = "jq"):
    """Registers jq toolchain and repositories

    Args:
        version: the version of jq to execute (see https://github.com/stedolan/jq/releases)
        name: override the prefix for the generated toolchain repositories
    """
    for platform in JQ_PLATFORMS.keys():
        jq_platform_repo(
            name = "%s_toolchains_%s" % (name, platform),
            platform = platform,
            jq_version = version,
        )
        native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    jq_toolchains_repo(
        name = "%s_toolchains" % name,
    )
