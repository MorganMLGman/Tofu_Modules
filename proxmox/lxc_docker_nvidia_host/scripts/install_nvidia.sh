#!/bin/bash
set -euo pipefail

# Idempotent NVIDIA driver + container toolkit installation for LXC containers
# Requires: NVIDIA devices passed through from host, host already has kernel modules loaded
# Driver version must match the host kernel module version exactly.

DRIVER_VERSION="${nvidia_driver_version}"
DRIVER_FILE="NVIDIA-Linux-x86_64-$DRIVER_VERSION.run"
DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/$DRIVER_FILE"

# --- NVIDIA userspace driver ---

if nvidia-smi &>/dev/null; then
  echo "NVIDIA driver already installed: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
else
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y wget

  echo "Downloading NVIDIA driver $DRIVER_VERSION..."
  wget -q "$DRIVER_URL" -O "/tmp/$DRIVER_FILE"
  chmod +x "/tmp/$DRIVER_FILE"

  # --no-kernel-modules: kernel modules live on the host, not in the LXC
  "/tmp/$DRIVER_FILE" --no-kernel-modules -s
  rm "/tmp/$DRIVER_FILE"

  echo "NVIDIA driver installed: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
fi

# --- NVIDIA Container Toolkit ---

if nvidia-ctk --version &>/dev/null && [ -f /etc/docker/daemon.json ] && grep -q "nvidia" /etc/docker/daemon.json; then
  echo "NVIDIA Container Toolkit already configured"
else
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y curl gpg

  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  apt-get update
  apt-get install -y nvidia-container-toolkit

  nvidia-ctk runtime configure --runtime=docker
  systemctl restart docker

  echo "NVIDIA Container Toolkit installed: $(nvidia-ctk --version)"
fi

echo "NVIDIA setup complete"
nvidia-smi
