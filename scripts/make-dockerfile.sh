#!/bin/bash

set -euo pipefail

declare -r GROUP="$1"
declare -r OUTPUTDIR="$2"
declare -r DOWNLOAD="$3"
declare -r TITLE="$4"

# Do not use these directly in the sed below - it will mask git failures
BUILD_VERSION="${BUILD_VERSION:-dev}"
CI_COMMIT_SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"

sed -e "s|TEMPLATE_ROOTFS_FILE|$GROUP.tar.zst|" \
    -e "s|TEMPLATE_ROOTFS_DOWNLOAD|$DOWNLOAD|" \
    -e "s|TEMPLATE_ROOTFS_HASH|$(cat $OUTPUTDIR/$GROUP.tar.zst.SHA256)|" \
    -e "s|TEMPLATE_TITLE|Arch Linux $TITLE Image|" \
    -e "s|TEMPLATE_VERSION_ID|$BUILD_VERSION|" \
    -e "s|TEMPLATE_REVISION|$CI_COMMIT_SHA|" \
    -e "s|TEMPLATE_CREATED|$(date -Is)|" \
    Dockerfile.template > "$OUTPUTDIR/Dockerfile.$GROUP"
