#!/bin/bash
set -ex

# Add customizations to the GPU image here.
ln -s /usr/bin/buildkit-runc /usr/bin/runc
