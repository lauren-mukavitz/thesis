
#!/usr/bin/env bash
set -euo pipefail

SOURCE="/mnt/d/Mukavitz Thesis/Satellite Data"
DEST="$HOME/vazante_gmtsar/data/raw"
BATCH="${1:?Usage: bash 12_prepare_batch_processing.sh batch.txt}"

mkdir -p "$DEST"

while IFS= read -r file || [[ -n "$file" ]]; do
    [[ -z "$file" || "$file" == \#* ]] && continue

    src="$SOURCE/$file"
    dst="$DEST/$(basename "$file")"

    if [[ ! -f "$src" ]]; then
        echo "ERROR: Missing archive: $src"
        exit 1
    fi

    echo "Copying: $file"
    cp -n "$src" "$dst"

done < "$BATCH"

echo "Batch copied."


