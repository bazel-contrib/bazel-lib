#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

case "$(uname -s)" in
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        bazel run @jq//:jq.exe -- --null-input .a=5
        ;;

    *)
        bazel run @jq//:jq -- --null-input .a=5
        ;;
esac

