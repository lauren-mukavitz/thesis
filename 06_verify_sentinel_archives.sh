#!/bin/bash

for file in "/mnt/d/Mukavitz Thesis/Satellite Data"/*/*.zip; do
    [ -f "$file" ] || continue

    zip_date=$(basename "$file" | cut -c1-10 | tr -d _)
    safe_date=$(unzip -Z -1 "$file" | grep -oEm1 '20[0-9]{6}T[0-9]{6}' | cut -c1-8)

    if [ "$zip_date" = "$safe_date" ]; then
        echo "$(basename "$file"): MATCH"
    else
        echo "$(basename "$file"): MISMATCH"
    fi
done

