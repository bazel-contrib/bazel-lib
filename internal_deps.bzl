"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

load("//lib:repositories.bzl", "register_bats_toolchains", "register_coreutils_toolchains", "register_jq_toolchains", "register_tar_toolchains", "register_yq_toolchains")
load("//lib:utils.bzl", http_archive = "maybe_http_archive")

# buildifier: disable=unnamed-macro
def bazel_lib_internal_deps():
    "Fetch deps needed for local development"
    http_archive(
        name = "io_bazel_rules_go",
        sha256 = "80a98277ad1311dacd837f9b16db62887702e9f1d1c4c9f796d0121a46c8e184",
        urls = ["https://github.com/bazelbuild/rules_go/releases/download/v0.46.0/rules_go-v0.46.0.zip"],
    )

    http_archive(
        name = "bazel_gazelle",
        integrity = "sha256-dd8ojEsxyB61D1Hi4U9HY8t1SNquEmgXJHBkY3/Z6mI=",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.36.0/bazel-gazelle-v0.36.0.tar.gz"],
    )

    http_archive(
        name = "bazel_skylib_gazelle_plugin",
        sha256 = "747addf3f508186234f6232674dd7786743efb8c68619aece5fb0cac97b8f415",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-gazelle-plugin-1.5.0.tar.gz"],
    )

    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz"],
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "ec57139e466faae563f2fc39609da4948a479bb51b6d67aedd7d9b1b8059c433",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.5.4/stardoc-0.5.4.tar.gz",
            "https://github.com/bazelbuild/stardoc/releases/download/0.5.4/stardoc-0.5.4.tar.gz",
        ],
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "8ada9d88e51ebf5a1fdff37d75ed41d51f5e677cdbeafb0a22dda54747d6e07e",
        strip_prefix = "buildifier-prebuilt-6.4.0",
        urls = ["http://github.com/keith/buildifier-prebuilt/archive/6.4.0.tar.gz"],
    )

    http_archive(
        name = "aspect_rules_lint",
        sha256 = "604666ec7ffd4f5f2636001ae892a0fbc29c77401bb33dd10601504e3ba6e9a7",
        strip_prefix = "rules_lint-0.6.1",
        url = "https://github.com/aspect-build/rules_lint/releases/download/v0.6.1/rules_lint-v0.6.1.tar.gz",
    )

    http_archive(
        name = "bazel_features",
        sha256 = "1aabce613b3ed83847b47efa69eb5dc9aa3ae02539309792a60e705ca4ab92a5",
        strip_prefix = "bazel_features-0.2.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v0.2.0/bazel_features-v0.2.0.tar.gz",
    )

    # Register toolchains for tests
    register_jq_toolchains()
    register_yq_toolchains()
    register_coreutils_toolchains()
    register_tar_toolchains()
    register_bats_toolchains(
        libraries = ["@aspect_bazel_lib//lib/tests/bats/bats-custom:custom"],
    )
