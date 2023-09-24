#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Configuration for 'git archive'
# see https://git-scm.com/docs/git-archive/2.40.0#ATTRIBUTES
cat >.git/info/attributes <<EOF
# Omit folders that users don't need, making the distribution artifact smaller
lib/tests export-ignore

# Substitution for the _VERSION_PRIVATE placeholder
tools/version.bzl export-subst
EOF

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="bazel-lib-${TAG:1}"
ARCHIVE="bazel-lib-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

cat << EOF

## Using Bzlmod with Bazel 6:

1. Enable with \`common --enable_bzlmod\` in \`.bazelrc\`.
2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "aspect_bazel_lib", version = "${TAG:1}")
\`\`\`

> Read more about bzlmod: <https://blog.aspect.dev/bzlmod>

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "aspect_bazel_lib",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/aspect-build/bazel-lib/releases/download/${TAG}/${ARCHIVE}",
)

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies()

\`\`\`

Optional toolchains:

\`\`\`starlark
# Register the following toolchain to use jq

load("@aspect_bazel_lib//lib:repositories.bzl", "register_jq_toolchains")

register_jq_toolchains()

# Register the following toolchain to use yq

load("@aspect_bazel_lib//lib:repositories.bzl", "register_yq_toolchains")

register_yq_toolchains()
\`\`\`
EOF
