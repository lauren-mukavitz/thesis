#!/bin/bash
set -e

cd ~/vazante_gmtsar

LOG="logs/05_sentinel_inspection.log"
mkdir -p logs

{
    for zip in /mnt/d/"Mukavitz Thesis"/"Satellite Data"/*/*.zip; do
        [ -f "$zip" ] || continue

        echo "======================================"
        echo "Scene: $(basename "$zip")"
        echo "Year: $(basename "$(dirname "$zip")")"
        unzip -Z -1 "$zip" | sed -n '1,20p'
        echo
    done
} > "$LOG"

echo "Inspection saved to: $LOG"
