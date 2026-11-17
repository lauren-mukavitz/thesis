#!/usr/bin/env bash
set -euo pipefail

cd ~/vazante_gmtsar
mkdir -p results/interferograms

python3 - <<'PY'
from pathlib import Path
import rasterio
from rasterio.mask import mask
from rasterio.vrt import WarpedVRT
from shapely.geometry import Point, mapping
from shapely.ops import transform
from pyproj import Transformer

center = Point(-46.85268, -17.95507)
to_utm = Transformer.from_crs(4326, 32723, always_xy=True).transform
to_geo = Transformer.from_crs(32723, 4326, always_xy=True).transform
area = transform(to_geo, transform(to_utm, center).buffer(10000))

files = sorted(Path("processing/F2/intf_all").rglob("unwrap_ll.grd"))

if not files:
    raise RuntimeError("No geocoded unwrapped interferograms found")

for file in files:
    output = Path("results/interferograms") / f"{file.parent.name}_10km_unwrapped.tif"

    with rasterio.open(file) as src:
        with WarpedVRT(src, src_crs="EPSG:4326", crs="EPSG:4326") as vrt:
            data, affine = mask(vrt, [mapping(area)], crop=True)

            profile = vrt.profile.copy()
            profile.update(
                driver="GTiff",
                crs="EPSG:4326",
                height=data.shape[1],
                width=data.shape[2],
                transform=affine
            )

            with rasterio.open(output, "w", **profile) as dst:
                dst.write(data)

    print(f"Saved: {output.name}")

print(f"Clipped {len(files)} interferograms.")
PY