#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

flag="--@bazel_lib//lib:diff_test_validation"
out="lib/tests/write_source_files/a2.js"
trap 'git checkout -- "$out"' EXIT

bazel test "$flag" //lib/tests/diff_test/... //lib/tests/write_source_files/...

expect_out_of_date() {
  if bazel "$@" 2>stderr.log; then
    echo "ERROR: expected 'bazel $*' to fail when $out is out of date"
    exit 1
  fi
  if ! grep -q "bazel run //lib/tests/write_source_files:macro_smoke_test_0" stderr.log; then
    cat stderr.log
    echo "ERROR: expected 'bazel $*' to print the command that updates $out"
    exit 1
  fi
}

echo 'console.log("out of date");' >>"$out"
expect_out_of_date build "$flag" //lib/tests/write_source_files:macro_smoke_test_0_test
expect_out_of_date test --build_tests_only "$flag" //lib/tests/write_source_files:macro_smoke_test_0_test
rm stderr.log

# The out-of-date check must not stop the update target from running
bazel run "$flag" //lib/tests/write_source_files:macro_smoke_test_0
bazel build "$flag" //lib/tests/write_source_files:macro_smoke_test_0_test
echo "All tests passed"
