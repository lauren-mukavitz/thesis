#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p logs

python3 - <<'PY' | tee logs/07_orbit_metadata.log
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET

for file in sorted(Path("/mnt/d/Mukavitz Thesis/Satellite Data").glob("*/*.zip")):
    with ZipFile(file) as z:
        manifest = next(n for n in z.namelist() if n.endswith("manifest.safe"))
        root = ET.fromstring(z.read(manifest))

    print(f"\n{file.parent.name}/{file.name}")
    for tag in ("orbitNumber", "relativeOrbitNumber", "pass", "startTime", "stopTime"):
        values = dict.fromkeys(
            e.text.strip() for e in root.iter()
            if e.tag.endswith(tag) and e.text
        )
        print(f"{tag}: {', '.join(values) or 'Not found'}")
PY
