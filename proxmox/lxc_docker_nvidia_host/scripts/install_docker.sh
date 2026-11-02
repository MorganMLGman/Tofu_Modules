#!/bin/bash
set -euo pipefail

# Idempotent Docker CE installation for Debian/Ubuntu LXC containers

DOCKER_NEEDS_RESTART=false

if command -v docker &>/dev/null; then
  echo "Docker is already installed: $(docker --version)"
else
  DOCKER_NEEDS_RESTART=true
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates curl gnupg

  install -m 0755 -d /etc/apt/keyrings

  # Detect distribution
  . /etc/os-release

  curl -fsSL "https://download.docker.com/linux/$ID/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
fi

%{ if docker_compose ~}
# Install docker-compose plugin if not present
if ! docker compose version &>/dev/null; then
  apt-get update
  apt-get install -y docker-compose-plugin
fi
%{ endif ~}

# Write daemon configuration
%{ if docker_daemon_config != "" ~}
mkdir -p /etc/docker
NEW_DAEMON_CONFIG=$(cat << 'DAEMON_EOF'
${docker_daemon_config}
DAEMON_EOF
)
if [ ! -f /etc/docker/daemon.json ] || [ "$(cat /etc/docker/daemon.json)" != "$NEW_DAEMON_CONFIG" ]; then
  echo "$NEW_DAEMON_CONFIG" > /etc/docker/daemon.json
  DOCKER_NEEDS_RESTART=true
fi
%{ endif ~}

%{ if docker_enable_tcp ~}
# Configure Docker to listen on TCP
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf << 'OVERRIDE_EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:${docker_tcp_port} --containerd=/run/containerd/containerd.sock
OVERRIDE_EOF
systemctl daemon-reload
%{ endif ~}

systemctl enable docker

if [ "$DOCKER_NEEDS_RESTART" = true ]; then
  systemctl restart docker
  echo "Docker restarted"
else
  echo "Docker already running, no restart needed"
fi

echo "Docker installation complete: $(docker --version)"
