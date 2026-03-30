#!/bin/bash

set -euo pipefail

declare -r ROOTFS_FILE="$1"
declare -r GROUP="$2"
declare -r OUTPUTDIR="$3"
declare -r DOWNLOAD="$4"
declare -r TITLE="$5"
declare -rx SOURCE_DATE_EPOCH="$6"

# Do not use these directly in the sed below - it will mask git failures
BUILD_VERSION="${BUILD_VERSION:-dev}"
CI_COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"

# Honor SOURCE_DATE_EPOCH for the repro GROUP
if [[ "$GROUP" == "repro" ]]; then
    CREATED_TIMESTAMP=$(date -u -d "@$SOURCE_DATE_EPOCH" +%Y-%m-%dT%H:%M:%SZ)
else
    CREATED_TIMESTAMP=$(date -Is)
fi

sed -e "s|TEMPLATE_ROOTFS_FILE|$ROOTFS_FILE|" \
    -e "s|TEMPLATE_ROOTFS_DOWNLOAD|$DOWNLOAD|" \
    -e "s|TEMPLATE_ROOTFS_HASH|$(cat $OUTPUTDIR/$ROOTFS_FILE.SHA256)|" \
    -e "s|TEMPLATE_TITLE|Arch Linux $TITLE Image|" \
    -e "s|TEMPLATE_VERSION_ID|$BUILD_VERSION|" \
    -e "s|TEMPLATE_REVISION|$CI_COMMIT_SHA|" \
    -e "s|TEMPLATE_CREATED|$CREATED_TIMESTAMP|" \
    Dockerfile.template > "$OUTPUTDIR/Dockerfile.$GROUP"
