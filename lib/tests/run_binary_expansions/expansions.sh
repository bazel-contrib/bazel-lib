#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

mkdir -p $(dirname $1)
outfile=$1
rm -f $outfile
for each in $@
do
  sanitized=${each/darwin/PLATFORM}
  sanitized=${sanitized/k8/PLATFORM}
  echo $sanitized >> $outfile
done
