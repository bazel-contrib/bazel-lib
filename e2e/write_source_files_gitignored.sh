#!/bin/bash

set -e

bazel run //lib/tests/write_source_files:write_dist
