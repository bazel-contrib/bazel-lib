#!/bin/bash

set -e

case "$(uname -s)" in
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        bazel run @yq//:yq.exe -- --null-input .a=5
        ;;

    *)
        bazel run @yq//:yq -- --null-input .a=5
        ;;
esac