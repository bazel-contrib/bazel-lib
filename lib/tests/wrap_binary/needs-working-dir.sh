#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

if [ "$(dirname $(pwd))" != "wrap_binary" ]; then
  echo >&2 "this program must be run with the working directory inside the package, but was $(pwd)"
  exit 1
fi