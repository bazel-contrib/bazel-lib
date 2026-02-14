#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Hello, World!" > "$1"
