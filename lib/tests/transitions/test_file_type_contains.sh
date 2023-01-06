#!/usr/bin/env bash

# Test whether the output of `file` contains a text string.
#
# Usage: test_file_type_contains.sh <filePath> <text>

set -o errexit -o nounset -o pipefail

file --dereference "$1" | grep -q "$2"
