
#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p results/interferograms

python3 - <<'PY'
from pathlib import Path
import rasterio
from rasterio.mask import mask
from shapely.geometry import Point, mapping
from shapely.ops import transform
from pyproj import Transformer

# Create 10 km buffer around Vazante
to_utm = Transformer.from_crs(4326, 32723, always_xy=True).transform
to_geo = Transformer.from_crs(32723, 4326, always_xy=True).transform

buffer = transform(to_geo,
    transform(to_utm, Point(-46.85268, -17.95507)).buffer(10000))

# Clip all interferograms
for file in Path("processing").rglob("phasefilt_mask_ll.grd"):
    output = Path("results/interferograms") / f"{file.parent.name}_10km.tif"

    if output.exists():
        continue

    with rasterio.open(file) as src:
        data, affine = mask(src, [mapping(buffer)], crop=True)
        profile = src.profile.copy()
        profile.update(driver="GTiff", height=data.shape[1],
                       width=data.shape[2], transform=affine)

        with rasterio.open(output, "w", **profile) as dst:
            dst.write(data)

    print(f"Saved: {output.name}")
PY
