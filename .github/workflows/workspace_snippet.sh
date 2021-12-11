#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
TAG_NO_PREFIX=${TAG:1}
SHA=$(git archive --format=tar --prefix=bazel-lib-${TAG_NO_PREFIX}/ ${TAG} | gzip | shasum -a 256 | awk '{print $1}')

cat << EOF

WORKSPACE snippet:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "aspect_bazel_lib",
    sha256 = "${SHA}",
    url = "https://github.com/aspect-build/bazel-lib/archive/${TAG}.tar.gz",
)
\`\`\`
EOF
