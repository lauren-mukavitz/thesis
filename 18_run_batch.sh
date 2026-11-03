
#!/usr/bin/env bash
set -e

cd ~/vazante_gmtsar/processing/F2/raw

# Link downloaded precise orbit files
for file in ../../orbit/*.EOF; do
    [ -f "$file" ] || continue
    ln -sfn "$(realpath "$file")" .
done

# Generate data.in
python3 - <<'PY'
from pathlib import Path
from datetime import datetime

lines = []

for xml in sorted(Path(".").glob("*iw2*vv*.xml")):
    parts = xml.stem.split("-")
    satellite = parts[0].upper()
    date = datetime.strptime(parts[4], "%Y%m%dt%H%M%S")
    matches = []

    for orbit in Path(".").glob("*.EOF"):
        if satellite not in orbit.name.upper().split("_"):
            continue

        start, end = orbit.stem.split("_V")[-1].split("_")

        if (datetime.strptime(start, "%Y%m%dT%H%M%S")
                <= date <=
                datetime.strptime(end, "%Y%m%dT%H%M%S")):
            matches.append(orbit.name)

    if len(matches) != 1:
        raise RuntimeError(
            f"Expected one orbit for {xml.name}, found {len(matches)}"
        )

    lines.append(f"{xml.stem}:{matches[0]}")

if not lines:
    raise RuntimeError("No IW2 VV annotation files found")

Path("data.in").write_text("\n".join(lines) + "\n")
print(f"Created data.in with {len(lines)} scenes")
PY

# Preprocess scenes
preproc_batch_tops.csh data.in ../topo/dem.grd 2

# Generate interferogram pairs within 48 days
python3 - <<'PY'
from pathlib import Path
from datetime import datetime
from itertools import combinations

scenes = []

for file in Path(".").glob("S1_*_ALL_F2.PRM"):
    name = file.stem
    date = datetime.strptime(name.split("_")[1], "%Y%m%d")
    scenes.append((date, name))

scenes.sort()
pairs = []

for (date1, name1), (date2, name2) in combinations(scenes, 2):
    if 0 < (date2 - date1).days <= 48:
        pairs.append(f"{name1}:{name2}")

if not pairs:
    raise RuntimeError("No valid interferogram pairs found")

Path("intf.in").write_text("\n".join(pairs) + "\n")
print(f"Created intf.in with {len(pairs)} pairs")
PY

# Generate interferograms
intf_tops.csh intf.in batch_tops.config
