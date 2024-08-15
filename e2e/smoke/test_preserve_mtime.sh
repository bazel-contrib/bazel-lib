#!/usr/bin/env bash

set -euo pipefail

function main {
  compareMTimes d/1 copy_to_directory_mtime_out/d/1
  compareMTimes d/1 copy_directory_mtime_out/1
}

function mtime {
    local file="$1"
    if [[ "$(uname)" == "Linux" ]]; then
        stat --dereference --format=%y "$file"
    elif [[ "$(uname)" == "Darwin" ]]; then
        stat -L -f %m "$file"
    else
        echo "untested"
    fi
}

function compareMTimes {
  local originalFile="$1"
  local copiedFile="$2"

    local mtimeOriginal
    mtimeOriginal="$(mtime "$originalFile")"

    local mtimeCopy
    mtimeCopy="$(mtime "$copiedFile")"

  if [[ "$mtimeOriginal" != "$mtimeCopy" ]]; then
    echo "Preserve mtime test failed. Modify times do not match for $originalFile and $copiedFile"
    echo "  Original modify time: $mtimeOriginal"
    echo "  Copied modify time:   $mtimeCopy"
    return 1
  fi

  echo "Preserve mtime test passed for $originalFile and $copiedFile"
}

main "$@"
