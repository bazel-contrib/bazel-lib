#!/usr/bin/env bash
# Produce a dictionary for the current copy_directory tool release,
# suitable for adding to lib/private/copy_directory_toolchain.bzl

set -o errexit -o nounset -o pipefail

# Find the latest version
if [ "${1:-}" ]; then
    version=$1
else
    version=$(curl --silent "https://api.github.com/repos/aspect-build/bazel-lib/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

# Extract the checksums and output a starlark map entry
echo "COPY_DIRECTORY_VERSION = \"$version\""
echo "COPY_DIRECTORY_INTEGRITY = {"
platforms=(darwin_{amd64,arm64} linux_{amd64,arm64} windows_amd64)
for release in ${platforms[@]}; do
    integrity="https://github.com/aspect-build/bazel-lib/releases/download/v$version/copy_directory-$release"
    if [[ $release == windows* ]]; then
        integrity="$integrity.exe"
    fi
    integrity="$integrity.sha256"
    curl --silent --location $integrity -o "/tmp/$release.sha256"

    echo "    \"$release\": \"sha256-$(cat /tmp/$release.sha256 | awk '{ print $1 }' | xxd -r -p | base64)\","
done
echo "}"

printf "\n"
echo "Paste the above into lib/private/copy_directory_toolchain.bzl"
