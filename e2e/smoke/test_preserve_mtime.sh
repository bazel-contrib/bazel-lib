#!/usr/bin/env bash

set -euo pipefail

function main {
  compareMTimes d/1 copy_to_directory_mtime_out/d/1
  compareMTimes d/1 copy_directory_mtime_out/1
}

function compareMTimes {
  local originalFile="$1"
  local copiedFile="$2"

  local mtimeOriginal
  mtimeOriginal="$(stat --dereference --format=%y "$originalFile")"

  local mtimeCopy
  mtimeCopy="$(stat --dereference --format=%y "$copiedFile")"

  if [[ "$mtimeOriginal" != "$mtimeCopy" ]]; then
    echo "Preserve mtime test failed. Modify times do not match for $originalFile and $copiedFile"
    echo "  Original modify time: $mtimeOriginal"
    echo "  Copied modify time:   $mtimeCopy"
    return 1
  fi

  echo "Preserve mtime test passed for $originalFile and $copiedFile"
}

main "$@"
