#!/bin/bash

set -e

bazel run //lib/tests/write_source_files:write_dist
[ -e lib/tests/write_source_files/dist.js ]
