#thank you chatgpt for help with expanding to entire dataset
#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p logs

python3 - <<'PY' | tee logs/08_vazante_coverage.log
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

LAT, LON = -17.95507, -46.85268

for file in sorted(Path("/mnt/d/Mukavitz Thesis/Satellite Data").glob("*/*.zip")):
    print(f"\n{file.parent.name}/{file.name}")

    with ZipFile(file) as z:
        annotations = [
            n for n in z.namelist()
            if "/annotation/" in n
            and "-slc-vv-" in n.lower()
            and "-iw" in n.lower()
            and n.endswith(".xml")
        ]

        for name in sorted(annotations):
            root = ET.fromstring(z.read(name))
            points = []

            for p in root.iter():
                if p.tag.endswith("geolocationGridPoint"):
                    coords = {
                        e.tag.split("}")[-1]: e.text for e in p
                    }
                    points.append((float(coords["latitude"]), float(coords["longitude"])))

            if not points:
                continue

            lats, lons = zip(*points)
            inside = min(lats) <= LAT <= max(lats) and min(lons) <= LON <= max(lons)

            print(f"{Path(name).name}")
            print(f"  Latitude: {min(lats):.4f} to {max(lats):.4f}")
            print(f"  Longitude: {min(lons):.4f} to {max(lons):.4f}")
            print(f"  Mine within bounding box: {inside}")
PY
