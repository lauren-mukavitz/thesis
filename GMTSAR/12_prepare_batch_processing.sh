
#!/usr/bin/env bash
set -e

# Copy selected Sentinel-1 scenes from external drive to WSL

SOURCE="/mnt/d/Mukavitz Thesis/Satellite Data/2015"
DEST="$HOME/vazante_gmtsar/data/raw"

mkdir -p "$DEST"

for date in 07_05 11_14 11_26 12_08 12_20; do
    file="2015_${date}_S1A_IW_SLC__1SDV.zip"

    echo "Copying $file"
    cp -n "$SOURCE/$file" "$DEST/"
done

echo "All scenes copied."


