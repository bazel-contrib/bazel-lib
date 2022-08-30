#!/usr/bin/env bash
set -euo pipefail
F1="{file1}"
F2="{file2}"
[[ "$F1" =~ ^external/ ]] && F1="${F1#external/}" || F1="$TEST_WORKSPACE/$F1"
[[ "$F2" =~ ^external/ ]] && F2="${F2#external/}" || F2="$TEST_WORKSPACE/$F2"
if [[ -d "${RUNFILES_DIR:-/dev/null}" && "${RUNFILES_MANIFEST_ONLY:-}" != 1 ]]; then
  RF1="$RUNFILES_DIR/$F1"
  RF2="$RUNFILES_DIR/$F2"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  RF1="$(grep -F -m1 "$F1 " "$RUNFILES_MANIFEST_FILE" | sed 's/^[^ ]* //')"
  RF2="$(grep -F -m1 "$F2 " "$RUNFILES_MANIFEST_FILE" | sed 's/^[^ ]* //')"
elif [[ -f "$TEST_SRCDIR/$F1" && -f "$TEST_SRCDIR/$F2" ]]; then
  RF1="$TEST_SRCDIR/$F1"
  RF2="$TEST_SRCDIR/$F2"
else
  echo >&2 "ERROR: could not find \"{file1}\" and \"{file2}\""
  exit 1
fi
DF1=
DF2=
[[ ! -d "$RF1" ]] || DF1=1
[[ ! -d "$RF2" ]] || DF2=1
if [[ "$DF1" ]] && [[ ! "$DF2" ]]; then
  echo >&2 "ERROR: cannot compare a directory \"{file1}\" against a file \"{file2}\""
  exit 1
fi
if [[ ! "$DF1" ]] && [[ "$DF2" ]]; then
  echo >&2 "ERROR: cannot compare a file \"{file1}\" against a directory \"{file2}\""
  exit 1
fi
if [[ "$DF1" ]] || [[ "$DF2" ]]; then
  if ! diff -r "$RF1" "$RF2"; then
    echo >&2 "FAIL: directories \"{file1}\" and \"{file2}\" differ. {fail_msg}"
    exit 1
  fi
else
  if ! diff "$RF1" "$RF2"; then
    echo >&2 "FAIL: files \"{file1}\" and \"{file2}\" differ. {fail_msg}"
    exit 1
  fi
fi

