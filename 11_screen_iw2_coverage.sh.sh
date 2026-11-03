#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p logs results

python3 - <<'PY' | tee logs/11_iw2_coverage.log
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET
import csv

LAT, LON = -17.95507, -46.85268
results = []

def inside(x, y, polygon):
    result = False
    for (x1, y1), (x2, y2) in zip(polygon, polygon[1:] + polygon[:1]):
        if (y1 > y) != (y2 > y) and x < x1 + (y - y1) * (x2 - x1) / (y2 - y1):
            result = not result
    return result

for file in sorted(Path("/mnt/d/Mukavitz Thesis/Satellite Data").glob("*/*.zip")):
    with ZipFile(file) as z:
        names = [n for n in z.namelist() if "/annotation/" in n.lower()
                 and "-iw2-slc-vv-" in n.lower() and n.endswith(".xml")]
        if not names:
            print(f"{file.name}: No IW2 annotation")
            continue
        root = ET.fromstring(z.read(names[0]))

    points = {}
    for p in root.iter():
        if p.tag.endswith("geolocationGridPoint"):
            v = {e.tag.split("}")[-1]: e.text for e in p}
            points[int(v["line"]), int(v["pixel"])] = (
                float(v["longitude"]), float(v["latitude"]))

    if not points:
        print(f"{file.name}: No geolocation points")
        continue

    lines, pixels = zip(*points)
    corners = [(a, b) for a, b in [
        (min(lines), min(pixels)), (min(lines), max(pixels)),
        (max(lines), max(pixels)), (max(lines), min(pixels))
    ]]

    if not all(c in points for c in corners):
        print(f"{file.name}: Missing footprint corners")
        continue

    covered = inside(LON, LAT, [points[c] for c in corners])
    results.append([file.parent.name, file.name, covered])
    print(f"{file.name}: {covered}")

with open("results/iw2_coverage.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["year", "zip_filename", "iw2_approximate_coverage"])
    writer.writerows(results)

print(f"\nScenes screened: {len(results)}")
print(f"Scenes covering Vazante: {sum(r[2] for r in results)}")
PY
