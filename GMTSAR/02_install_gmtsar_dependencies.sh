#!/usr/bin/env bash
set -e

# Install GMTSAR dependencies
sudo apt install -y \
    git \
    build-essential \
    gfortran \
    csh \
    tcsh \
    cmake \
    libfftw3-dev \
    libnetcdf-dev \
    libgmt-dev \
    libtiff-dev \
    liblapack-dev \
    libblas-dev \
    python3 \
    python3-pip \
    snaphu \
    unzip 

echo "GMTSAR dependencies installed successfully."
