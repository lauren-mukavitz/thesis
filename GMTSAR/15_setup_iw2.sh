#!/usr/bin/env bash
set -e

cd ~/vazante_gmtsar/processing

mkdir -p F2/raw F2/topo orbit

for safe in ~/vazante_gmtsar/data/raw/*.SAFE; do
    [ -d "$safe" ] || continue
    ln -sfn "$safe"/annotation/*iw2*vv*.xml F2/raw/
    ln -sfn "$safe"/measurement/*iw2*vv*.tiff F2/raw/
done

echo "IW2 files prepared."
