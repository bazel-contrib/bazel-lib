"Macros for loading dependencies and registering toolchains"

load("//lib:utils.bzl", "is_bazel_6_or_greater", http_archive = "maybe_http_archive")
load("//lib/private:copy_directory_toolchain.bzl", "COPY_DIRECTORY_PLATFORMS", "copy_directory_platform_repo", "copy_directory_toolchains_repo")
load("//lib/private:copy_to_directory_toolchain.bzl", "COPY_TO_DIRECTORY_PLATFORMS", "copy_to_directory_platform_repo", "copy_to_directory_toolchains_repo")
load("//lib/private:coreutils_toolchain.bzl", "COREUTILS_PLATFORMS", "coreutils_platform_repo", "coreutils_toolchains_repo", _DEFAULT_COREUTILS_VERSION = "DEFAULT_COREUTILS_VERSION")
load("//lib/private:expand_template_toolchain.bzl", "EXPAND_TEMPLATE_PLATFORMS", "expand_template_platform_repo", "expand_template_toolchains_repo")
load("//lib/private:jq_toolchain.bzl", "JQ_PLATFORMS", "jq_host_alias_repo", "jq_platform_repo", "jq_toolchains_repo", _DEFAULT_JQ_VERSION = "DEFAULT_JQ_VERSION")
load("//lib/private:local_config_platform.bzl", "local_config_platform")
load("//lib/private:source_toolchains_repo.bzl", "source_toolchains_repo")
load("//lib/private:yq_toolchain.bzl", "YQ_PLATFORMS", "yq_host_alias_repo", "yq_platform_repo", "yq_toolchains_repo", _DEFAULT_YQ_VERSION = "DEFAULT_YQ_VERSION")
load("//tools:version.bzl", "VERSION")

# buildifier: disable=unnamed-macro
def aspect_bazel_lib_dependencies(override_local_config_platform = False):
    """Load dependencies required by aspect rules

    Args:
        override_local_config_platform: override the @local_config_platform repository with one that adds stardoc
            support for loading constraints.bzl.

            Should be set in repositories that load @aspect_bazel_lib copy actions and also generate stardoc.
    """
    http_archive(
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
        ],
    )

    # Bazel 6 now has the exports that our custom local_config_platform rule made
    # so it should never be needed when running Bazel 6 or newer
    # TODO(2.0): remove the override_local_config_platform attribute entirely
    if not is_bazel_6_or_greater() and override_local_config_platform:
        local_config_platform(
            name = "local_config_platform",
        )

    # Always register the copy_to_directory toolchain
    register_copy_directory_toolchains()
    register_copy_to_directory_toolchains()

    # Always register the expand_template toolchain
    register_expand_template_toolchains()

    # Always register the coreutils toolchain
    register_coreutils_toolchains()

# Re-export the default versions
DEFAULT_JQ_VERSION = _DEFAULT_JQ_VERSION
DEFAULT_YQ_VERSION = _DEFAULT_YQ_VERSION
DEFAULT_COREUTILS_VERSION = _DEFAULT_COREUTILS_VERSION

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

def register_coreutils_toolchains(name = "coreutils", version = DEFAULT_COREUTILS_VERSION, register = True):
    """Registers coreutils toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of coreutils to execute (see https://github.com/uutils/coreutils/releases)
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    for [platform, meta] in COREUTILS_PLATFORMS.items():
        coreutils_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    coreutils_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )

def register_copy_directory_toolchains(name = "copy_directory", register = True):
    """Registers copy_directory toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    if VERSION == "0.0.0":
        source_toolchains_repo(
            name = "%s_toolchains" % name,
            toolchain_type = "@aspect_bazel_lib//lib:copy_directory_toolchain_type",
            toolchain_rule_load_from = "@aspect_bazel_lib//lib/private:copy_directory_toolchain.bzl",
            toolchain_rule = "copy_directory_toolchain",
            binary = "@aspect_bazel_lib//tools/copy_directory",
        )
        if register:
            native.register_toolchains("@%s_toolchains//:toolchain" % name)
        return

    for [platform, meta] in COPY_DIRECTORY_PLATFORMS.items():
        copy_directory_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    copy_directory_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )

def register_copy_to_directory_toolchains(name = "copy_to_directory", register = True):
    """Registers copy_to_directory toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    if VERSION == "0.0.0":
        source_toolchains_repo(
            name = "%s_toolchains" % name,
            toolchain_type = "@aspect_bazel_lib//lib:copy_to_directory_toolchain_type",
            toolchain_rule_load_from = "@aspect_bazel_lib//lib/private:copy_to_directory_toolchain.bzl",
            toolchain_rule = "copy_to_directory_toolchain",
            binary = "@aspect_bazel_lib//tools/copy_to_directory",
        )
        if register:
            native.register_toolchains("@%s_toolchains//:toolchain" % name)
        return

    for [platform, meta] in COPY_TO_DIRECTORY_PLATFORMS.items():
        copy_to_directory_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    copy_to_directory_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )

def register_expand_template_toolchains(name = "expand_template", register = True):
    """Registers expand_template toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """
    if VERSION == "0.0.0":
        source_toolchains_repo(
            name = "%s_toolchains" % name,
            toolchain_type = "@aspect_bazel_lib//lib:expand_template_toolchain_type",
            toolchain_rule_load_from = "@aspect_bazel_lib//lib/private:expand_template_toolchain.bzl",
            toolchain_rule = "expand_template_toolchain",
            binary = "@aspect_bazel_lib//tools/expand_template",
        )
        if register:
            native.register_toolchains("@%s_toolchains//:toolchain" % name)
        return

    for [platform, meta] in EXPAND_TEMPLATE_PLATFORMS.items():
        expand_template_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    expand_template_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )
