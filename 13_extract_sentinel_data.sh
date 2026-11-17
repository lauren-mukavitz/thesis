#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

cd ~/vazante_gmtsar/data/raw

for file in *.zip; do
    echo "Extracting $file"
    unzip -n "$file"
done

echo "Extraction finished."
