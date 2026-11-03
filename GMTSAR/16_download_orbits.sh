
#!/usr/bin/env bash
set -e

cd ~/vazante_gmtsar/processing/orbit

for safe in ~/vazante_gmtsar/data/raw/*.SAFE; do
    scene=$(basename "$safe" .SAFE)
    echo "Downloading orbit for ${scene:17:8}"
    curl -fL --retry 3 \
        "https://s1-orbits.asf.alaska.edu/scene/$scene" \
        -OJ
done

echo "Orbit downloads complete."
