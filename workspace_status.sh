#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# This script is called by Bazel when it needs info about the git state.
# The --workspace_status_command flag tells Bazel the location of this script.
# This is configured in `/.bazelrc`.
set -o pipefail -o errexit -o nounset

function has_local_changes {
    if [ "$(git status --porcelain)" != "" ]; then
        echo dirty
    else
        echo clean
    fi
}

# "stable" keys, should remain constant over rebuilds, therefore changed values will cause a
# rebuild of any stamped action that uses ctx.info_file or genrule with stamp = True
# Note, BUILD_USER is automatically available in the stable-status.txt, it matches $USER
echo "STABLE_BUILD_SCM_SHA $(git rev-parse HEAD)"
echo "STABLE_BUILD_SCM_LOCAL_CHANGES $(has_local_changes)"

if [ "$(git tag | wc -l)" -gt 0 ]; then
    echo "STABLE_BUILD_SCM_TAG $(git describe --tags)"
fi
