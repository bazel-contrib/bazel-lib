#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

flag="--@bazel_lib//lib:diff_test_validation"
out="lib/tests/write_source_files/a2.js"
host_tools=$(mktemp -d)
trap 'git checkout -- "$out"; rm -rf "$host_tools"' EXIT

# Both comparison modes and the write_source_files tests must use the toolchain.
cat >"$host_tools/diff" <<'EOF'
#!/usr/bin/env bash
echo >&2 "ERROR: host diff was called"
exit 86
EOF
chmod +x "$host_tools/diff"
hermetic_flags=("--action_env=PATH=$host_tools:$PATH" "--test_env=PATH=$host_tools:$PATH")

bazel test "${hermetic_flags[@]}" --no@bazel_lib//lib:diff_test_validation //lib/tests/diff_test/... //lib/tests/write_source_files/...

bazel test "${hermetic_flags[@]}" "$flag" //lib/tests/diff_test/... //lib/tests/write_source_files/...

expect_out_of_date() {
  if bazel "$@" "${hermetic_flags[@]}" 2>stderr.log; then
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
