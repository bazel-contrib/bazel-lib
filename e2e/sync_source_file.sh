#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

out="lib/tests/sync_source_file/expected.txt"
log=$(mktemp)
trap 'git checkout -- "$out"; rm -f "$log"' EXIT

bazel build //lib/tests/sync_source_file:sync_file

echo "stale" >>"$out"
if bazel build //lib/tests/sync_source_file:sync_file >"$log" 2>&1; then
  echo >&2 "ERROR: expected a validation failure for the stale source file"
  exit 1
fi
if ! grep -q 'bazel run //lib/tests/sync_source_file:sync_file --norun_validations' "$log"; then
  cat "$log"
  echo >&2 "ERROR: expected the command to update the stale source file"
  exit 1
fi

# Skipping validations bypasses the check; there is no passing test to mislead users.
bazel build --norun_validations //lib/tests/sync_source_file:sync_file
bazel run //lib/tests/sync_source_file:sync_file --norun_validations
bazel build //lib/tests/sync_source_file:sync_file

# A missing file must report how to create it without blocking the updater.
rm "$out"
if bazel build //lib/tests/sync_source_file/... >"$log" 2>&1; then
  echo >&2 "ERROR: expected a failure for the missing source file"
  exit 1
fi
if ! grep -q 'bazel run //lib/tests/sync_source_file:sync_file --norun_validations' "$log"; then
  cat "$log"
  echo >&2 "ERROR: expected the command to create the source file"
  exit 1
fi
bazel run //lib/tests/sync_source_file:sync_file --norun_validations
bazel build //lib/tests/sync_source_file/...
