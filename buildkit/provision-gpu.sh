#!/bin/bash
set -ex

# Add customizations to the GPU image here.

systemctl disable docker.service
systemctl disable docker.socket

cat << EOF >  /etc/nvidia-container-runtime/config.toml
disable-require = false

[nvidia-container-cli]
environment = []
load-kmods = true
ldconfig = "@/sbin/ldconfig"

[nvidia-container-runtime]
log-level = "info"
mode = "auto"
# DEPOT: prefer buildkit-runc over runc and docker-runc
runtimes = [
    "buildkit-runc",
    "runc",
    "docker-runc",
]
    [nvidia-container-runtime.modes.csv]
    mount-spec-path = "/etc/nvidia-container-runtime/host-files-for-container.d"

EOF
