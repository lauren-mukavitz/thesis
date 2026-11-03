#!/usr/bin/env bash
set -e
cd ~/vazante_gmtsar

# Create directories for Sentinel-1 processing
mkdir -p data/raw
mkdir -p data/orbits
mkdir -p data/dem
mkdir -p processing
mkdir -p results/interferograms
mkdir -p results/deformation
mkdir -p logs

find . -maxdepth 3 -type d | sort