#!/usr/bin/env bash
set -o nounset

# Snippet to parse Bazel's status file format.
# https://github.com/bazelbuild/bazel/issues/11164#issuecomment-996186921
# is another option, which requires Bash 4 for associative arrays.
while IFS= read -r line; do
  read key value <<< "$line"
  declare $key="$value"
done < <(cat "${BAZEL_STABLE_STATUS_FILE:-/dev/null}" "${BAZEL_VOLATILE_STATUS_FILE:-/dev/null}")

# A real program would do something useful with the stamp info, like pass it to a linker.
echo "${BUILD_USER:-unstamped}" > $1
