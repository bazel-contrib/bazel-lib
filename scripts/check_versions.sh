#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail


TAG=
if [[ "${PRE_COMMIT:-"0"}" == "1" ]]; then
    if [[ ! $( echo "$PRE_COMMIT_REMOTE_BRANCH" | grep -E '^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' ) ]]; then
        # not pushing a tag. skip running.
        exit 0
    fi
    TAG="${PRE_COMMIT_REMOTE_BRANCH/refs\/tags\//}"
else
    if [[ $# -eq 0 ]]; then
        echo "a tag required."
        exit 1
    elif [[ ! $( echo "$1" | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+$' ) ]]; then
        echo "not a valid semver. expected v0.0.0 format."
        exit 1
    fi
    TAG=$1
fi

BAZEL_ARGS=(
    --client_env=STABLE_BUILD_SCM_TAG_OVERRIDE="$TAG"
    --test_output=errors
    --config=release
    --ui_event_filters=-stdout
    --noshow_progress
    //tools:release_versions_checkin_test
)
if ! bazel --bazelrc=.github/workflows/ci.bazelrc --bazelrc=.bazelrc test ${BAZEL_ARGS[@]};  then
    echo ""
    echo "Release is aborted to due to wrong version information."
    echo ""
    echo "> Please run the following command and retag with a new commit."
    echo ""
    echo "./scripts/generate_versions.sh $TAG"
    echo ""
    exit 1
fi
