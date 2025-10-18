This package reproduces issue #1058: `write_source_files` using the same file path as the copy that produced it.

Run `bazel test //lib/tests/write_source_files_repro:write_foobar_test` or `bazel run //lib/tests/write_source_files_repro:write_foobar` to see the behavior.

Expected: the generated `diff_test` fails with `diff_test comparing the same file` because `in` and `out` resolve to the same runfile.
