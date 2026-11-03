#!/usr/bin/env bash
set -e
sudo apt update

# Install GMT
sudo apt install -y gmt gmt-dcw gmt-gshhg
gmt --version
