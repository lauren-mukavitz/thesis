#Thank you Chatgpt for help
#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p logs

python3 - <<'PY' | tee logs/09_iw2_bursts.log
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET
from math import radians, sin, cos, asin, sqrt

LAT, LON = -17.95507, -46.85268

def distance(lat, lon):
    a = sin(radians(lat - LAT) / 2)**2 + cos(radians(LAT)) * cos(radians(lat)) * sin(radians(lon - LON) / 2)**2
    return 12742 * asin(sqrt(a))

for file in sorted(Path("/mnt/d/Mukavitz Thesis/Satellite Data").glob("*/*.zip")):
    print(f"\n{file.parent.name}/{file.name}")

    with ZipFile(file) as z:
        annotations = [
            n for n in z.namelist()
            if "/annotation/" in n.lower()
            and "-iw2-slc-vv-" in n.lower()
            and n.endswith(".xml")
        ]

        if not annotations:
            print("No IW2 VV annotation found")
            continue

        root = ET.fromstring(z.read(annotations[0]))

    points = []
    for p in root.iter():
        if p.tag.endswith("geolocationGridPoint"):
            values = {e.tag.split("}")[-1]: e.text for e in p}
            lat, lon = float(values["latitude"]), float(values["longitude"])
            points.append((distance(lat, lon), int(values["line"]), int(values["pixel"])))

    lines = root.find(".//{*}linesPerBurst")
    bursts = root.findall(".//{*}burstList/{*}burst")

    if not points:
        print("No geolocation points found")
        continue

    km, line, pixel = min(points)
    print(f"Nearest grid point: {km:.2f} km")
    print(f"Grid line/pixel: {line}, {pixel}")
    print(f"Lines per burst: {lines.text if lines is not None else 'Unknown'}")
    print(f"Total bursts: {len(bursts)}")

    if lines is not None and int(lines.text) > 0:
        burst = line // int(lines.text) + 1
        print(f"Approximate burst: {burst}")
        print(f"Burst within scene: {1 <= burst <= len(bursts)}")
PY