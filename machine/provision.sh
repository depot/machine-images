#!/bin/bash
set -ex

# Wait for cloud-init to finish
cloud-init status --wait

# Disable update-motd.service
systemctl disable update-motd.service

# Install Docker
dnf install -y docker
systemctl enable docker.service

# Install amazon-ssm-agent
dnf install -y amazon-ssm-agent

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
cat << EOF > /usr/lib/systemd/system/depot-agent.service
[Unit]
Description=Depot Agent
After=network-online.target docker.service vector.service
Requires=network-online.target docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker exec %n stop
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull ghcr.io/depot/agent:dev
ExecStart=/usr/bin/docker run --rm --privileged --net=host --name %n \
  -e DEPOT_CLOUD_CONNECTION_ID \
  -v /lib/modules:/lib/modules:ro \
  -v /etc/ceph:/etc/ceph \
  -v /dev:/dev \
  -v /sys:/sys \
  ghcr.io/depot/agent:dev

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable depot-agent.service

# Prepare cloud-init for shutdown
cloud-init clean --logs
