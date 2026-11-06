#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
fail() {
  echo >&2 "FAIL: $1"
  exit 1
}
F1="{file1_path}"
F2="{file2_path}"
DF1=
DF2=
[[ ! -d "$F1" ]] || DF1=1
[[ ! -d "$F2" ]] || DF2=1
if [[ "$DF1" ]] && [[ ! "$DF2" ]]; then
  echo >&2 "ERROR: cannot compare a directory \"{file1}\" against a file \"{file2}\""
  exit 1
fi
if [[ ! "$DF1" ]] && [[ "$DF2" ]]; then
  echo >&2 "ERROR: cannot compare a file \"{file1}\" against a directory \"{file2}\""
  exit 1
fi
if [[ "$DF1" ]] || [[ "$DF2" ]]; then
  if ! diff {diff_args} -r "$F1" "$F2" >&2; then
    fail "directories \"{file1}\" and \"{file2}\" differ. {fail_msg}"
  fi
else
  if ! diff {diff_args} "$F1" "$F2" >&2; then
    fail "files \"{file1}\" and \"{file2}\" differ. {fail_msg}"
  fi
fi
touch "{validated}"
