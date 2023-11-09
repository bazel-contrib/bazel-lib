#!/bin/bash

set -o errexit -o nounset -o pipefail

function get_nar () {
    local platform="$1"
    nix-env --uninstall libarchive.\* 2>&2
    nix-env -iA --prebuilt-only --attr nixpkgs.pkgsStatic.libarchive --argstr system "$platform" 2>&2
    hash=$(nix-env -q --out-path libarchive.\* --no-name | cut -c12-43)

    nar=$(curl -fsSL "https://cache.nixos.org/$hash.narinfo" | grep 'URL: ' | tr -d "URL: ")
    nar_url="https://cache.nixos.org/$nar"

    archive="$(mktemp)"
    curl -fsSL $nar_url | gzcat > $archive
    sha256=$(curl -fsSL $nar_url | shasum -a 256 | awk '{print $1}')
    range=$(./scripts/read_nar.sh "$archive")
    echo "  \"$2\": (\"$nar_url\", \"$sha256\", $range)"
}


nl=$'\n'
output="EXPERIMENTAL_NIXOS_BSDTAR_TOOLCHAINS = {$nl"
output+="$(get_nar aarch64-linux linux_arm64),$nl"
output+="$(get_nar x86_64-linux linux_amd64),$nl"
output+="$(get_nar aarch64-darwin darwin_arm64)$nl"
output+="}"

clear

echo "$output"
