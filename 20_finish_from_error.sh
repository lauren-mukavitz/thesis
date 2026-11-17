#!/usr/bin/env bash
set -euo pipefail

PROJECT="$HOME/vazante_gmtsar"
DRIVE="/mnt/d/Mukavitz Thesis/Processed Data"

mkdir -p "$DRIVE/intf_all" "$DRIVE/clipped"

# Copy interferograms
rsync -avhL \
    "$PROJECT/processing/F2/intf_all/" \
    "$DRIVE/intf_all/"

# Copy clipped GeoTIFFs
rsync -avh \
    "$PROJECT/results/interferograms/" \
    "$DRIVE/clipped/"

# Verify transfers
echo "Verifying files..."

if [ -n "$(rsync -rcniL "$PROJECT/processing/F2/intf_all/" "$DRIVE/intf_all/")" ]; then
    echo "ERROR: Interferogram verification failed."
    exit 1
fi

if [ -n "$(rsync -rcni "$PROJECT/results/interferograms/" "$DRIVE/clipped/")" ]; then
    echo "ERROR: Clipped file verification failed."
    exit 1
fi

echo "All files transferred and verified successfully."
echo "No local files were deleted."