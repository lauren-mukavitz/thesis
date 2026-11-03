#!/bin/bash
set -e

cd ~/vazante_gmtsar
mkdir -p processing/topo

#Makes it so I dont regenerate a DEM if it already exists. This is useful if you have to rerun the script for some reason.

if [ ! -f processing/topo/dem.grd ]; then
    cd processing/topo
    make_dem.csh -47.5 -45.9 -19.4 -17.3 1
fi

ln -sfn ../topo/dem.grd processing/F2/topo/dem.grd

echo "DEM prepared."
