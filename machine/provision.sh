#!/bin/bash
set -ex

# Wait for cloud-init to finish
cloud-init status --wait

# Update all packages
dnf update -y

# Disable kdump
systemctl disable kdump.service
grubby --update-kernel=ALL --remove-args=crashkernel=auto

# Install Docker
dnf install -y podman

# Install amazon-ssm-agent
if [[ $(uname -m) == "aarch64" ]]; then
  dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
else
  dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi

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

# Configure Depot agent
cat << EOF > /etc/containers/systemd/depot-agent.container
[Unit]
Description=Depot agent

[Container]
Image=ghcr.io/depot/agent:dev
ContainerName=depot-agent
Volume=/lib/modules:/lib/modules:ro
Volume=/etc/ceph:/etc/ceph
Volume=/dev:/dev
Volume=/sys:/sys
PodmanArgs=--privileged
# Exec=sleep infinity

[Service]
Restart=always
TimeoutStartSec=900

[Install]
WantedBy=multi-user.target default.target
EOF
systemctl daemon-reload

# Prepare cloud-init for shutdown
cloud-init clean --logs
