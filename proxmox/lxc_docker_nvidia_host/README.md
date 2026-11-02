# lxc_docker_nvidia_host - Terraform Module for Proxmox LXC Docker Hosts with NVIDIA GPU

> **Deprecated.** Use [`proxmox/lxc`](../lxc/) (`docker = {}`, `nvidia = {...}`). See [MIGRATION.md](../../MIGRATION.md).

Extension of `lxc_docker_host` that adds NVIDIA GPU passthrough and container toolkit setup.

## Description

This module combines LXC container creation with Docker CE and NVIDIA GPU support:
- All features of `lxc_docker_host` (Docker CE, Compose, TCP socket, additional scripts)
- Automatic NVIDIA device passthrough (nvidia0, nvidiactl, nvidia-uvm, nvidia-uvm-tools, nvidia-caps)
- Userspace NVIDIA driver installation (`--no-kernel-modules`) matching the host driver
- NVIDIA Container Toolkit installation and Docker runtime configuration
- `nvidia` tag auto-appended alongside `tofu`, `ci`, `docker`

### Prerequisites

The **Proxmox host** must have:
1. NVIDIA kernel modules loaded (`nvidia`, `nvidia_uvm`)
2. NVIDIA driver installed (same version as `nvidia_driver_version` variable)
3. `nvidia-smi` working on the host

The LXC container **does not** need kernel modules — it shares them with the host.

### Lifecycle Safety

Inherits the same lifecycle safety as `lxc_docker_host`. NVIDIA install script is idempotent.

## Requirements

- OpenTofu >= 1.11.2
- Proxmox VE 7.x or higher
- Privileged LXC container (`ct_unprivileged = false`, which is the default)
- Debian or Ubuntu LXC template
- SSH key authorized on the LXC (via `ct_user_ssh_keys`) and available locally
- Providers:
  - `bpg/proxmox` ~> 0.89.1
  - `loafoe/ssh` ~> 2.7
  - `hashicorp/time` ~> 0.12

## Inputs (Variables)

All variables from `lxc_docker_host` are supported. NVIDIA-specific additions:

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `node_name` | `string` | Proxmox node name |
| `ct_hostname` | `string` | Container hostname |
| `ct_operating_system_template_file_id` | `string` | Template file ID |
| `nvidia_driver_version` | `string` | Driver version matching the host (e.g. `"580.142"`) |

### Optional (NVIDIA-specific)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `nvidia_devices` | `list(string)` | standard 6-device set | NVIDIA device paths to pass through |
| `ct_unprivileged` | `bool` | `false` | Must be `false` for device passthrough |

All other variables are identical to `lxc_docker_host`. See its README for full reference.

## Usage Example

```hcl
module "lxc_ai_worker" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_nvidia_host?ref=v1.0.0"

  node_name   = "bigpc"
  ct_hostname = "lxc-ai-worker"

  ct_operating_system_template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  ct_operating_system_type             = "debian"

  ct_memory_dedicated = 8192
  ct_cpu_cores        = 4
  ct_disk_size        = 32

  ct_network_interfaces = [{ bridge = "vmbr0" }]
  ct_ip_configs         = [{ ipv4_address = "dhcp" }]

  ct_user_ssh_keys = [file("~/.ssh/id_ed25519.pub")]
  ct_tags          = ["ai"]

  # Must match the driver on the Proxmox host
  nvidia_driver_version = "580.142"

  ssh_agent = true
}
```

### Custom device list (multi-GPU)

```hcl
module "lxc_multi_gpu" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_nvidia_host?ref=v1.0.0"

  # ... other variables ...

  nvidia_driver_version = "580.142"

  nvidia_devices = [
    "/dev/nvidia0",
    "/dev/nvidia1",
    "/dev/nvidiactl",
    "/dev/nvidia-uvm",
    "/dev/nvidia-uvm-tools",
    "/dev/nvidia-caps/nvidia-cap1",
    "/dev/nvidia-caps/nvidia-cap2",
  ]
}
```

## Related Modules

- [`lxc_docker_host`](../lxc_docker_host/) — Base module without NVIDIA support
- [`docker_service`](../../docker/service/) — Companion module for managing Docker containers on this host
