#!/bin/bash
set -ex

# Wait for cloud-init to finish
cloud-init status --wait

# Disable update-motd.service
systemctl disable update-motd.service

# Install Docker
dnf install -y docker
systemctl enable docker.service

# Install Vector

curl -1sLf 'https://repositories.timber.io/public/vector/cfg/setup/bash.rpm.sh' | bash
dnf install -y vector
systemctl enable vector
mkdir -p /etc/vector
cat <<EOF > /etc/vector/vector.toml
[sources.docker]
type = "docker_logs"

[sinks.grafana]
type = "loki"
inputs = ["docker"]
endpoint = "https://logs-prod-006.grafana.net"
encoding.codec = "json"
labels.source = "machine"
auth.strategy = "basic"
auth.user = "613342"
auth.password = "${LOG_TOKEN}"
EOF

# Prepare cloud-init for shutdown
cloud-init clean --logs
