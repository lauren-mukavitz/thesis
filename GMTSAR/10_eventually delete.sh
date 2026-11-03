#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p logs

python3 - <<'PY' | tee logs/10_iw2_footprints.log
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

LAT, LON = -17.95507, -46.85268

def inside_polygon(x, y, corners):
    inside = False
    for (x1, y1), (x2, y2) in zip(corners, corners[1:] + corners[:1]):
        if (y1 > y) != (y2 > y):
            if x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                inside = not inside
    return inside

for file in sorted(Path("/mnt/d/Mukavitz Thesis/Satellite Data").glob("*/*.zip")):
    print(f"\n{file.parent.name}/{file.name}")

    with ZipFile(file) as z:
        annotations = [
            n for n in z.namelist()
            if "-iw2-slc-vv-" in n.lower()
            and "/annotation/" in n.lower()
            and n.endswith(".xml")
        ]

        if not annotations:
            print("No IW2 VV annotation found")
            continue

        root = ET.fromstring(z.read(annotations[0]))

    points = {}
    for p in root.iter():
        if p.tag.endswith("geolocationGridPoint"):
            v = {e.tag.split("}")[-1]: e.text for e in p}
            points[int(v["line"]), int(v["pixel"])] = (
                float(v["longitude"]), float(v["latitude"])
            )

    if not points:
        print("No geolocation points found")
        continue

    lines, pixels = zip(*points)
    corners = [
        (min(lines), min(pixels)),
        (min(lines), max(pixels)),
        (max(lines), max(pixels)),
        (max(lines), min(pixels))
    ]

    if not all(c in points for c in corners):
        print("Missing footprint corners")
        continue

    polygon = [points[c] for c in corners]

    print(f"Mine inside IW2 footprint: {inside_polygon(LON, LAT, polygon)}")
    for lon, lat in polygon:
        print(f"  {lat:.6f}, {lon:.6f}")
PY