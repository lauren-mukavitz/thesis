
#!/usr/bin/env bash
set -euo pipefail

cd ~/vazante_gmtsar/processing/orbit

for safe in ~/vazante_gmtsar/data/raw/*.SAFE; do        #for loop added because a few files were downloaded as XML files instead of EOF files. This should fix if ever hapens again
    [ -d "$safe" ] || continue
    scene=$(basename "$safe" .SAFE)

    curl -fL --retry 3 \
        "https://s1-orbits.asf.alaska.edu/scene/$scene" \
        -o "$scene"

    name=$(sed -n 's/.*<File_Name>\(.*\)<\/File_Name>.*/\1/p' "$scene" | head -1)

    if [ -z "$name" ]; then
        echo "ERROR: Could not identify orbit filename for $scene"
        exit 1
    fi

    mv "$scene" "${name%.EOF}.EOF"
done

echo "Orbit downloads complete."
