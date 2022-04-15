#!/bin/bash/env bash
# Produce a dictionary for the current yq release,
# suitable for adding to lib/private/yq_toolchain.bzl

set -o errexit

# Find the latest version
version=$(curl --silent "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# yq publishes its checksums and a script to extract them
curl --silent --location "https://github.com/mikefarah/yq/releases/download/$version/extract-checksum.sh" -o /tmp/extract-checksum.sh
curl --silent --location "https://github.com/mikefarah/yq/releases/download/$version/checksums_hashes_order" -o /tmp/checksums_hashes_order
curl --silent --location "https://github.com/mikefarah/yq/releases/download/$version/checksums" -o /tmp/checksums

cd /tmp
chmod u+x extract-checksum.sh

# Extract the checksums and output a starlark map entry
echo "\"$version\": {"
for release in darwin_{amd,arm}64 linux_{386,amd64} windows_{386,amd64}; do
    artifact=$release
    if [[ $release == windows* ]]; then
        artifact="$release.exe"
    fi
    echo "    \"$release\": \"$(./extract-checksum.sh SHA-384 $artifact | awk '{ print $2 }' | xxd -r -p | base64 | awk '{ print "sha384-" $1 }' )\","
done
echo "},"

printf "\n"
echo "Paste the above into VERSIONS in yq_toolchain.bzl."