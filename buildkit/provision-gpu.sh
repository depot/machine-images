#!/bin/bash
set -ex

# Add customizations to the GPU image here.
ln -s /usr/bin/buildkit-runc /usr/bin/runc

systemctl disable docker.service
systemctl disable docker.socket
