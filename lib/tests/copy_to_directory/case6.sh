#!/usr/bin/env bash

set -o errexit -o nounset

cd $TEST_SRCDIR
cd $TEST_WORKSPACE
cd $(dirname $TEST_BINARY)
cd case_6

# A path that should be in the directory we have in data[]
path="f/f2/f2"
if [ ! -f "$path" ]; then
    echo >&2 "Expected $path to exist in runfiles"
    exit 1
fi
