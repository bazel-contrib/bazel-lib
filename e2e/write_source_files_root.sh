#!/bin/bash

set -e

bazel run //:write_source_file_root-test
[ -e test-out/dist/write_source_file_root-test/test.txt ]
