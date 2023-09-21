#!/bin/bash

set -euo pipefail

declare -r GROUP="$1"
declare -r OUTPUTDIR="$2"

sed -e "s|TEMPLATE_ROOTFS_FILE|$GROUP.tar.zst|" \
    -e "s|TEMPLATE_ROOTFS_RELEASE_URL|Local build|" \
    -e "s|TEMPLATE_ROOTFS_DOWNLOAD|ROOTFS=\"$GROUP.tar.zst\"|" \
    -e "s|TEMPLATE_ROOTFS_HASH|$(cat $OUTPUTDIR/$GROUP.tar.zst.SHA256)|" \
    -e "s|TEMPLATE_TITLE|Arch Linux Dev Image|" \
    -e "s|TEMPLATE_VERSION_ID|dev|" \
    -e "s|TEMPLATE_REVISION|$(git rev-parse HEAD)|" \
    -e "s|TEMPLATE_CREATED|$(date -Is)|" \
    Dockerfile.template > "$OUTPUTDIR/Dockerfile.$GROUP"
