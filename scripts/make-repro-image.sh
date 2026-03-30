#!/bin/bash

set -euo pipefail

declare -r ORIG_OUTPUTDIR="$1"
declare -r REPRO_BUILDDIR="$2"
declare -r REPRO_OUTPUTDIR="$3"
declare -r ARCHIVE_SNAPSHOT="$4"
declare -rx SOURCE_DATE_EPOCH="$5"

echo -e "\n-- Testing the image reproducibility --\n"
make BUILDDIR="$REPRO_BUILDDIR" OUTPUTDIR="$REPRO_OUTPUTDIR" ARCHIVE_SNAPSHOT="$ARCHIVE_SNAPSHOT" SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH"
echo "The sha256 hash of the original image is:"
sha256sums "$ORIG_OUTPUTDIR/<image>"
echo "The sha256 hash of the reproduced image is:"
sha256sums "$REPRO_OUTPUTDIR/<image>"
diffoscope "$ORIG_OUTPUTDIR/<image>" "$REPRO_OUTPUTDIR/<image>" && echo -e "\nImage is reproducible!"
