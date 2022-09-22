#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

tty --silent || {
  echo >&2 "this program must be run with a tty attached to stdin, but was $(tty)"
  exit 1
}