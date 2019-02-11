#!/bin/bash

# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# End to end tests for unittest.bzl.
# 
# Specifically, end to end tests of unittest.bzl cover verification that
# analysis-phase tests written with unittest.bzl appropriately
# cause test failures in cases where violated assertions are made.

# --- begin runfiles.bash initialization ---
set -euo pipefail
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  if [[ -f "$0.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  elif [[ -f "$0.runfiles/MANIFEST" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
  elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
            "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---

source "$(rlocation bazel_skylib/tests/unittest.bash)" \
  || { echo "Could not source bazel_skylib/tests/unittest.bash" >&2; exit 1; }

function set_up() {
  touch WORKSPACE
  cat > WORKSPACE <<EOF
workspace(name = 'bazel_skylib')

load("//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()
EOF

  touch tests/BUILD
  cat > tests/BUILD <<EOF
exports_files(["*.bzl"])
EOF

  touch lib/BUILD
  cat > lib/BUILD <<EOF
exports_files(["*.bzl"])
EOF

  mkdir -p testdir
  cat > testdir/BUILD <<EOF
load("//tests:unittest_tests.bzl",
    "basic_passing_test",
    "basic_failing_test")

basic_passing_test(name = "basic_passing_test")

basic_failing_test(name = "basic_failing_test")
EOF
}

function tear_down() {
  rm -rf testdir
}

function test_basic_passing_test() {
  bazel test //testdir:basic_passing_test >"$TEST_log" 2>&1 || fail "Expected test to pass"

  expect_log "PASSED"
}

function test_basic_failing_test() {
  ! bazel test //testdir:basic_failing_test --test_output=all --verbose_failures \
      >"$TEST_log" 2>&1 || fail "Expected test to fail"

  expect_log "In test _basic_failing_test from //tests:unittest_tests.bzl: Expected \"1\", but got \"2\""
}

run_suite "unittest test suite"
