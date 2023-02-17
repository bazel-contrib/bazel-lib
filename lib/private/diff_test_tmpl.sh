#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
escape() {
  echo "$1" \
    | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g' \
    | awk 1 ORS='&#10;' # preserve newlines
}
fail() {
  cat << EOF >"${XML_OUTPUT_FILE:-/dev/null}"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="$(escape "{name}")" tests="1" failures="1">
  <testsuite name="$(escape "{name}")" tests="1" failures="1" id="0">
    <testcase name="$(escape "{name}")" assertions="1" status="failed">
      <failure message="$(escape "$1")" type="diff"></failure>
    </testcase>
  </testsuite>
</testsuites>
EOF
  echo >&2 "FAIL: $1"
  exit 1
}
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
    fail "directories \"{file1}\" and \"{file2}\" differ. {fail_msg}"
  fi
else
  if ! diff "$RF1" "$RF2"; then
    fail "files \"{file1}\" and \"{file2}\" differ. {fail_msg}"
  fi
fi
