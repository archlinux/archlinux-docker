#!/bin/bash

set -euo pipefail

declare -r ROOTFS_FILE="$1"
declare -r GROUP="$2"
declare -r OUTPUTDIR="$3"
declare -r DOWNLOAD="$4"
declare -r TITLE="$5"

# Do not use these directly in the sed below - it will mask git failures
BUILD_VERSION="${BUILD_VERSION:-dev}"
CI_COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"

sed -e "s|TEMPLATE_ROOTFS_FILE|$ROOTFS_FILE|" \
    -e "s|TEMPLATE_ROOTFS_DOWNLOAD|$DOWNLOAD|" \
    -e "s|TEMPLATE_ROOTFS_HASH|$(cat $OUTPUTDIR/$ROOTFS_FILE.SHA256)|" \
    -e "s|TEMPLATE_TITLE|Arch Linux $TITLE Image|" \
    -e "s|TEMPLATE_VERSION_ID|$BUILD_VERSION|" \
    -e "s|TEMPLATE_REVISION|$CI_COMMIT_SHA|" \
    -e "s|TEMPLATE_CREATED|$(date -Is)|" \
    Dockerfile.template > "$OUTPUTDIR/Dockerfile.$GROUP"
