"Macros for loading dependencies and registering toolchains"

load("//lib/private:jq_toolchain.bzl", "JQ_PLATFORMS", "jq_host_alias_repo", "jq_platform_repo", "jq_toolchains_repo", _DEFAULT_JQ_VERSION = "DEFAULT_JQ_VERSION")
load("//lib/private:yq_toolchain.bzl", "YQ_PLATFORMS", "yq_host_alias_repo", "yq_platform_repo", "yq_toolchains_repo", _DEFAULT_YQ_VERSION = "DEFAULT_YQ_VERSION")
load("//lib/private:local_config_platform.bzl", "local_config_platform")
load("//lib:utils.bzl", "is_bazel_6_or_greater", http_archive = "maybe_http_archive")

def aspect_bazel_lib_dependencies(override_local_config_platform = False):
    """Load dependencies required by aspect rules

    Args:
        override_local_config_platform: override the @local_config_platform repository with one that adds stardoc
            support for loading constraints.bzl.

            Should be set in repositories that load @aspect_bazel_lib copy actions and also generate stardoc.
    """
    http_archive(
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
    )

    # Bazel 6 now has the exports that our custom local_config_platform rule made
    # so it should never be needed when running Bazel 6 or newer
    # TODO(2.0): remove the override_local_config_platform attribute entirely
    if not is_bazel_6_or_greater() and override_local_config_platform:
        local_config_platform(
            name = "local_config_platform",
        )

# Re-export the default versions
DEFAULT_JQ_VERSION = _DEFAULT_JQ_VERSION
DEFAULT_YQ_VERSION = _DEFAULT_YQ_VERSION

def register_jq_toolchains(name = "jq", version = DEFAULT_JQ_VERSION, register = True):
    """Registers jq toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of jq to execute (see https://github.com/stedolan/jq/releases)
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    for [platform, meta] in JQ_PLATFORMS.items():
        jq_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    jq_host_alias_repo(name = name)

    jq_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )

def register_yq_toolchains(name = "yq", version = DEFAULT_YQ_VERSION, register = True):
    """Registers yq toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of yq to execute (see https://github.com/mikefarah/yq/releases)
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    for [platform, meta] in YQ_PLATFORMS.items():
        yq_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    yq_host_alias_repo(name = name)

    yq_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )
