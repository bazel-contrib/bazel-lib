#!/usr/bin/env bash

set -o errexit -o nounset

expected_file="$1"
source_file="$2"
bin_file="$3"
if [[ "$expected_file" != "$source_file" ]]; then
  echo "ERROR: expected source_file to be $expected_file, but got $source_file"
  exit 1
fi
if [[ "$bin_file" != "bazel-out/"* ]]; then
  echo "ERROR: expected bin_file to be start with bazel-out/, but got $bin_file"
  exit 1
fi
if [[ "$bin_file" != *"/bin/$expected_file" ]]; then
  echo "ERROR: expected bin_file to be end with /bin/$expected_file, but got $bin_file"
  exit 1
fi
