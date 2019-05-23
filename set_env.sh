#! /usr/bin/env bash

echo "Set environment"

echo "Start to install prerequisites"
sudo apt update
sudo apt-get install python -y
sudo apt-get install python-pip -y
pip install requests
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker $USER
