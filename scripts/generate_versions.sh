#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

if [[ $# -eq 0 ]]; then
    echo "a tag required."
    exit 1
fi

bazel --bazelrc=.github/workflows/ci.bazelrc --bazelrc=.bazelrc run --config=release --client_env=STABLE_BUILD_SCM_TAG_OVERRIDE="$1" //tools:release_versions_checkin
