
#!/usr/bin/env bash
set -e

# Set up GMTSAR batch processing for Vazante

PROJECT="$HOME/vazante_gmtsar"
RAW="$PROJECT/data/raw"
WORK="$PROJECT/processing"

mkdir -p "$WORK/raw" "$WORK/topo"

# Link extracted Sentinel-1 products into GMTSAR workspace
for safe in "$RAW"/*.SAFE; do
    ln -sfn "$safe" "$WORK/raw/"
done

# Create a list of Sentinel-1 scenes
find "$WORK/raw" -maxdepth 1 -name "*.SAFE" -printf "%f\n" | sort > "$WORK/scene_list.txt"

echo "GMTSAR batch workspace prepared."

