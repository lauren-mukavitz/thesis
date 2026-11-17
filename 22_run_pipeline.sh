
#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="$HOME/vazante_gmtsar"
DRIVE="/mnt/d/Mukavitz Thesis"
ARCHIVE="$DRIVE/Satellite Data"
OUTPUT="$DRIVE/Processed Data"
SOURCE="$PROJECT/processing/F2/intf_all"
BATCH_DIR="$PROJECT/batches"

cd "$PROJECT"
mkdir -p logs "$BATCH_DIR"
exec > >(tee -a logs/22_pipeline.log) 2>&1

echo "Pipeline started: $(date)"

[[ -d "$ARCHIVE" ]] || { echo "Satellite archive missing"; exit 1; }

for cmd in python3 rsync unzip preproc_batch_tops.csh intf_tops.csh snaphu; do
    command -v "$cmd" >/dev/null || { echo "Missing command: $cmd"; exit 1; }
done

for step in \
    12_prepare_batch_processing.sh \
    13_extract_sentinel_data.sh \
    14_setup_gmtsar_batch.sh \
    15_setup_iw2.sh \
    16_download_orbits.sh \
    17_prepare_dem.sh \
    18_run_batch.sh \
    19_clip_interferogram.sh
do
    [[ -f "$step" ]] || { echo "Missing script: $step"; exit 1; }
done

grep -Eq '^[[:space:]]*threshold_snaphu[[:space:]]*=[[:space:]]*0\.12' \
    processing/F2/batch_tops.config || {
    echo "SNAPHU threshold is not 0.12"
    exit 1
}

for dir in \
    data/raw \
    processing/raw \
    processing/F2/raw \
    processing/F2/intf_all \
    results/interferograms
do
    mkdir -p "$dir"
    if [[ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
        echo "ERROR: Existing files in $dir"
        echo "Move or back up existing processing files before starting."
        exit 1
    fi
done

python3 - "$ARCHIVE" "$BATCH_DIR" <<'PY'
from pathlib import Path
from datetime import datetime
import re
import sys

archive = Path(sys.argv[1])
batch_dir = Path(sys.argv[2])

files = []

for file in archive.rglob("*.zip"):
    match = re.match(r"(\d{4})_(\d{2})_(\d{2})_S1[ABC]_IW_SLC", file.name)
    if match:
        date = datetime.strptime("-".join(match.groups()), "%Y-%m-%d")
        files.append((date, file.relative_to(archive)))

files.sort()

if not files:
    raise RuntimeError("No Sentinel-1 archives found")

for old in batch_dir.glob("batch_*.txt"):
    old.unlink()

for start in range(0, len(files), 8):
    current = files[start:start + 8]
    first_date = current[0][0]

    overlap = [
        item for item in files[:start]
        if 0 <= (first_date - item[0]).days <= 48
    ]

    selected = overlap + current
    batch = batch_dir / f"batch_{start // 8 + 1:03d}.txt"

    batch.write_text(
        "\n".join(str(path) for _, path in selected) + "\n"
    )

print(f"Found {len(files)} archives")
print(f"Created {len(list(batch_dir.glob('batch_*.txt')))} batches")
PY

mkdir -p "$OUTPUT/intf_all" "$OUTPUT/interferograms"

verify_copy() {
    local source="$1"
    local destination="$2"
    local differences

    differences=$(rsync -rcni --delete "$source/" "$destination/")

    if [[ -n "$differences" ]]; then
        echo "ERROR: Transfer verification failed"
        echo "$differences"
        return 1
    fi
}

clean_directory() {
    local dir="$1"
    find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

for batch in "$BATCH_DIR"/batch_*.txt; do
    echo "Starting $(basename "$batch"): $(date)"

    bash 12_prepare_batch_processing.sh "$batch"

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        cmp -s "$ARCHIVE/$file" "data/raw/$(basename "$file")" || {
            echo "ERROR: Archive copy verification failed: $file"
            exit 1
        }
    done < "$batch"

    for step in \
        13_extract_sentinel_data.sh \
        14_setup_gmtsar_batch.sh \
        15_setup_iw2.sh \
        16_download_orbits.sh \
        17_prepare_dem.sh \
        18_run_batch.sh \
        19_clip_interferogram.sh
    do
        echo "Running $step"
        bash "$PROJECT/$step"
    done

    [[ -d "$SOURCE" ]] || { echo "No interferogram directory"; exit 1; }

    unwrapped=$(find "$SOURCE" -name "unwrap.grd" | wc -l)
    [[ "$unwrapped" -gt 0 ]] || {
        echo "ERROR: No unwrapped interferograms"
        exit 1
    }

    rsync -avh --ignore-existing "$SOURCE/" "$OUTPUT/intf_all/"
    rsync -avh --ignore-existing \
        "$PROJECT/results/interferograms/" \
        "$OUTPUT/interferograms/"

    verify_copy "$SOURCE" "$OUTPUT/intf_all"
    verify_copy "$PROJECT/results/interferograms" "$OUTPUT/interferograms"

    echo "Results verified. Cleaning local batch."

    clean_directory "$PROJECT/data/raw"
    clean_directory "$PROJECT/processing/raw"
    clean_directory "$PROJECT/processing/F2/raw"
    clean_directory "$PROJECT/processing/F2/intf_all"
    clean_directory "$PROJECT/results/interferograms"

    echo "Completed $(basename "$batch"): $(date)"
done

echo "Pipeline completed: $(date)"
echo "Results saved to: $OUTPUT"

