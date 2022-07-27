#!/bin/bash
set -ex

# Update software
yum update -y
yum install -y git

# Disable unnecessary services
systemctl disable postfix.service
systemctl disable update-motd.service

# Install BuildKit

case "$(uname -m)" in
  aarch64) arch='arm64' ;;
  x86_64) arch='amd64' ;;
  *) echo >&2 "error: unsupported architecture: $(uname -m)"; exit 1 ;;
esac

curl -L "https://github.com/moby/buildkit/releases/download/v0.10.3/buildkit-v0.10.3.linux-${arch}.tar.gz" | \
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
gckeepstorage = 45000000000 # 45GB

[worker.containerd]
enabled = false
EOF
