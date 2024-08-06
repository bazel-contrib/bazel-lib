#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

bazel 2>/dev/null query --output=label 'kind(starlark_doc_extract, //...)' | xargs bazel build
bazel cquery --output=files 'kind(starlark_doc_extract, //...)'
