#!/bin/bash

set -e

bazel run //lib/tests/write_source_files:write_subdir
[ -e lib/tests/write_source_files/subdir_test/a/b/c/test.txt ]

bazel run //lib/tests/write_source_files:write_subdir
[ -e lib/tests/write_source_files/subdir_test/a/b/c/test.txt ]
