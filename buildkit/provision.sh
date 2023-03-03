#!/bin/bash
set -ex

# Update software
yum update -y
yum install -y git

# Disable unnecessary services
systemctl disable postfix.service
systemctl disable update-motd.service

# Configure swap
dd if=/dev/zero of=/swapfile bs=128M count=32
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
echo "vm.swappiness = 0" >> /etc/sysctl.conf

# Download machine-agent v1.5.0

wget -O /tmp/machine-agent.tar.gz "https://dl.depot.dev/machine-agent/download/linux/$(uname -m)/v1.5.0"
tar -zxf /tmp/machine-agent.tar.gz --strip-components=1 --directory /usr/bin bin/machine-agent
/usr/bin/machine-agent --version

# Install BuildKit

case "$(uname -m)" in
  aarch64) arch='arm64' ;;
  x86_64) arch='amd64' ;;
  *) echo >&2 "error: unsupported architecture: $(uname -m)"; exit 1 ;;
esac

buildkit_version="v0.11.3-depot.1"
curl -L "https://github.com/depot/buildkit/releases/download/${buildkit_version}/buildkit-${buildkit_version}.linux-${arch}.tar.gz" | \
  tar -xz -C /usr/bin --strip-components=1

mkdir -p /etc/buildkit
cat <<EOF > /etc/buildkit/buildkitd.toml
root = "/var/lib/buildkit"

[grpc]
address = ["tcp://0.0.0.0:443", "unix:///run/buildkit/buildkitd.sock"]

[grpc.tls]
cert = "/etc/buildkit/tls.crt"
key = "/etc/buildkit/tls.key"
ca = "/etc/buildkit/tlsca.crt"

[worker.oci]
enabled = true
gc = true
gckeepstorage = 30000000000 # 30GB
max-parallelism = 12

[worker.containerd]
enabled = false

[[worker.oci.gcpolicy]]
keepBytes = 10240000000 # 10 GB
keepDuration = 604800 # 7 days - 3600 * 24 * 7
filters = [
  "type==source.local",
  "type==exec.cachemount",
  "type==source.git.checkout",
]

[[worker.oci.gcpolicy]]
keepBytes = 30000000000 # 30 GB

[[worker.oci.gcpolicy]]
all = true
keepBytes = 30000000000 # 30 GB
EOF
