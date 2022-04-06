#!/bin/bash

set -e

bazel run //lib/tests/write_source_files:write_symlinks

# Ensure exists
[ -e lib/tests/write_source_files/symlink_test/a/test.txt ]
[ -e lib/tests/write_source_files/symlink_test/b/test.txt ]

# Exit if any symlinks
[ -L lib/tests/write_source_files/symlink_test/a/test.txt ] && exit 1
[ -L lib/tests/write_source_files/symlink_test/b/test.txt ] && exit 1