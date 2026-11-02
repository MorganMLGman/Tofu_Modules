# lxc_docker_host - Terraform Module for Proxmox LXC Docker Hosts

> **Deprecated.** Use [`proxmox/lxc`](../lxc/) (`docker = {}`). See [MIGRATION.md](../../MIGRATION.md).

Terraform/OpenTofu module for creating Proxmox LXC containers with Docker CE pre-installed, designed to serve as long-lived Docker hosts managed by the `kreuzwerker/docker` provider.

## Description

This module combines LXC container creation with idempotent Docker CE installation:
- LXC container creation from OS templates with Docker-optimized defaults
- Automatic Docker CE installation via SSH provisioning
- Docker provider connection outputs for seamless integration with `kreuzwerker/docker`
- Optional Docker Compose plugin installation
- Optional TCP socket exposure for remote Docker API access
- Additional user scripts executed after Docker installation

### Key Design: LXC Stability

This module does **not** replace the LXC container when the provisioner script changes. The Docker install script is idempotent — changes are re-applied via SSH without destroying the container or its Docker workloads.

```
Container Created → wait_for_ip → time_sleep → SSH: install Docker → Docker ready
```

### Lifecycle Safety

| Change | LXC Effect | Docker Container Effect |
|--------|-----------|------------------------|
| Docker container config change | None | Container replaced |
| Docker image update | None | Container replaced |
| Docker install script update (module upgrade) | None (re-runs idempotently) | None |
| LXC CPU/memory/network change | In-place update | None |
| Additional provisioner script change | None (re-runs via SSH) | None |

## Requirements

- OpenTofu >= 1.11.2 / Terraform >= 1.11.2
- Proxmox VE 7.x or higher
- Debian or Ubuntu LXC template (Docker CE installation requirement)
- SSH key authorized on the LXC (via `ct_user_ssh_keys`) and available locally
- Providers:
  - `bpg/proxmox` ~> 0.89.1
  - `loafoe/ssh` ~> 2.7
  - `hashicorp/time` ~> 0.12

## Inputs (Variables)

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `node_name` | `string` | Proxmox node name |
| `ct_hostname` | `string` | Container hostname |
| `ct_operating_system_template_file_id` | `string` | Template file ID (e.g. `local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`) |

### Optional

#### Docker Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `docker_install_compose` | `bool` | `true` | Install docker-compose plugin |
| `docker_daemon_config` | `string` | `(log rotation JSON)` | Custom daemon.json content |
| `docker_enable_tcp` | `bool` | `false` | Expose Docker daemon on TCP port |
| `docker_tcp_port` | `number` | `2376` | TCP port for Docker daemon |
| `ct_additional_provisioner_script_content` | `string` | `""` | Additional script to run after Docker install |

#### Container Identity
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_id` | `number` | `null` | Container ID (auto-assigned if null) |
| `ct_description` | `string` | `""` | Container description |
| `ct_tags` | `list(string)` | `[]` | Tags (`tofu`, `ci`, and `docker` are auto-appended) |

#### Container Behavior
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_unprivileged` | `bool` | `true` | Run as unprivileged container |
| `ct_protection` | `bool` | `false` | Enable deletion protection |
| `ct_started` | `bool` | `true` | Start container after creation |
| `ct_start_on_boot` | `bool` | `true` | Start on Proxmox boot |

#### Operating System
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_operating_system_type` | `string` | `"ubuntu"` | OS type (alpine, archlinux, centos, debian, devuan, fedora, gentoo, nixos, opensuse, ubuntu, unmanaged) |

#### CPU and Memory
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_cpu_architecture` | `string` | `"amd64"` | CPU architecture (amd64, arm64, armhf, i386) |
| `ct_cpu_cores` | `number` | `1` | Number of CPU cores |
| `ct_cpu_units` | `number` | `1024` | CPU units (scheduler weight) |
| `ct_memory_dedicated` | `number` | `1024` | Dedicated memory (MB) — increased from 512 for Docker |
| `ct_memory_swap` | `number` | `512` | Swap size (MB) |

#### Disk
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_disk_datastore_id` | `string` | `"local-lvm"` | Datastore for root filesystem |
| `ct_disk_size` | `number` | `16` | Root filesystem size (GB) — increased from 8 for Docker images |
| `ct_disk_mount_options` | `list(string)` | `[]` | Root filesystem mount options |

#### Features
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_feature_nesting` | `bool` | `true` | Enable nested containers (required for Docker) |
| `ct_feature_fuse` | `bool` | `false` | Enable FUSE support |
| `ct_feature_keyctl` | `bool` | `true` | Enable keyctl system calls (required for Docker in LXC) |
| `ct_feature_mount` | `list(string)` | `[]` | Allowed mount types (e.g. `["nfs", "fuse"]`) |

#### Console
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_console` | `object` | `{enabled=true, type="shell", tty_count=2}` | Console configuration |

#### Network
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_network_interfaces` | `list(object)` | `[{name="eth0", bridge="vmbr0"}]` | Network interfaces |
| `ct_ipv4_address` | `string` | `"dhcp"` | IPv4 address in CIDR notation or `dhcp` |
| `ct_ipv4_gateway` | `string` | `null` | IPv4 gateway (auto-derived from subnet as `.1` when `null`) |
| `ct_dns_servers` | `list(string)` | `[]` | DNS servers (empty = DHCP-provided or none) |

> **Gateway auto-derivation:** When `ct_ipv4_gateway` is not set and a static IP is used, the gateway is automatically derived as the first usable IP in the subnet (e.g. `192.168.1.100/24` → gateway `192.168.1.1`). Set `ct_ipv4_gateway` explicitly to override.

#### User Account
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_user_ssh_keys` | `list(string)` | `[]` | SSH public keys for root |
| `ct_user_password` | `string` | `""` | Root password (sensitive) |

#### Mount Points
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_mount_points` | `list(object)` | `[]` | Additional mount points |

#### Device Passthrough
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_device_passthrough` | `list(object)` | `[]` | Devices to pass through |

#### Startup
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_startup_order` | `number` | `1` | Boot order |
| `ct_startup_up_delay` | `number` | `0` | Delay after start (s) |
| `ct_startup_down_delay` | `number` | `0` | Delay on stop (s) |

#### Timeouts
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ct_timeouts` | `object` | `{create=1800, delete=60, update=1800, clone=1800}` | Operation timeouts (s) |
| `ct_wait_for_ip_ipv4` | `bool` | `true` | Wait for IPv4 before ready |
| `ct_wait_for_ip_ipv6` | `bool` | `false` | Wait for IPv6 before ready |

#### SSH Connection
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ssh_user` | `string` | `"root"` | SSH user |
| `ssh_private_key` | `string` | `""` | SSH private key PEM content (sensitive, empty = use agent) |
| `ssh_agent` | `bool` | `true` | Use ssh-agent for authentication |
| `ssh_port` | `number` | `22` | SSH port |
| `ct_provisioner_timeout` | `string` | `"5m"` | SSH operation timeout |
| `ct_ssh_wait_duration` | `string` | `"15s"` | Boot delay before SSH |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `ct_id` | `number` | Container ID |
| `ct_hostname` | `string` | Container hostname |
| `ct_ipv4_address` | `string` | IPv4 address (first network interface) |
| `ct_status` | `string` | Container status (running/stopped) |
| `ct_node_name` | `string` | Node where container is running |
| `docker_install_result` | `string` | Stdout of Docker installation |
| `docker_host_ssh` | `string` | Docker provider SSH host string |
| `docker_host_tcp` | `string` | Docker provider TCP host string (null if TCP disabled) |
| `docker_ssh_opts` | `list(string)` | Recommended SSH options for Docker provider |

## Usage Examples

### Basic Docker Host with Static IP (Single State)

This is the recommended pattern for homelab environments where the IP is known ahead of time. The Docker provider is configured with the static IP, and `depends_on` ensures the LXC is ready before Docker containers are created.

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.89.1"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "~> 2.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://pve.example.com:8006"
  api_token = var.proxmox_api_token
  insecure  = true
}

provider "docker" {
  host     = "ssh://root@192.168.1.100:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

module "docker_host" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_host?ref=v3.0.0"

  node_name  = "pve"
  ct_hostname = "docker-01"

  ct_operating_system_template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  ct_operating_system_type             = "debian"

  ct_memory_dedicated = 4096
  ct_cpu_cores        = 4
  ct_disk_size        = 32

  ct_ipv4_address = "192.168.1.100/24"  # gateway auto-derived as 192.168.1.1
  ct_dns_servers  = ["1.1.1.1", "8.8.8.8"]

  ct_user_ssh_keys = [file("~/.ssh/id_ed25519.pub")]
}

# Deploy Docker containers using the docker_service module
module "nginx" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "nginx"
  image_name   = "nginx:latest"

  ports = [
    { internal = 80, external = 8080 }
  ]

  depends_on = [module.docker_host]
}

module "redis" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "redis"
  image_name   = "redis:7-alpine"

  ports = [
    { internal = 6379, external = 6379 }
  ]

  depends_on = [module.docker_host]
}
```

### Docker Host with TCP Socket

```hcl
module "docker_host_tcp" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_host?ref=v3.0.0"

  node_name  = "pve"
  ct_hostname = "docker-02"

  ct_operating_system_template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-1_amd64.tar.zst"

  ct_memory_dedicated = 2048
  ct_cpu_cores        = 2

  ct_ipv4_address = "192.168.1.101/24"  # gateway auto-derived as 192.168.1.1

  ct_user_ssh_keys = [file("~/.ssh/id_ed25519.pub")]

  # Expose Docker on TCP port
  docker_enable_tcp = true
  docker_tcp_port   = 2376
}

# Use TCP connection instead of SSH
provider "docker" {
  host = "tcp://192.168.1.101:2376"
}
```

### Docker Host with Additional Provisioning

```hcl
module "docker_host_custom" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_host?ref=v3.0.0"

  node_name  = "pve"
  ct_hostname = "docker-03"

  ct_operating_system_template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  ct_operating_system_type             = "debian"

  ct_memory_dedicated = 4096
  ct_cpu_cores        = 4
  ct_disk_size        = 64

  ct_ipv4_address = "192.168.1.102/24"  # gateway auto-derived as 192.168.1.1

  ct_user_ssh_keys = [file("~/.ssh/id_ed25519.pub")]
  ct_tags          = ["production"]

  # Custom daemon config
  docker_daemon_config = jsonencode({
    "log-driver" = "json-file"
    "log-opts" = {
      "max-size" = "50m"
      "max-file" = "5"
    }
    "storage-driver" = "overlay2"
    "default-address-pools" = [
      { "base" = "172.17.0.0/12", "size" = 24 }
    ]
  })

  # Additional script to run after Docker install
  ct_additional_provisioner_script_content = <<-EOT
    #!/bin/bash
    set -euo pipefail

    # Install monitoring agent
    apt-get install -y prometheus-node-exporter
    systemctl enable prometheus-node-exporter
    systemctl start prometheus-node-exporter

    echo "Additional provisioning complete"
  EOT
}
```

### Separate States (DHCP / Unknown IP)

When the LXC uses DHCP, the IP is not known at plan time. Use two separate states:

**State 1 — Infrastructure:**
```hcl
module "docker_host" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc_docker_host?ref=v3.0.0"

  node_name   = "pve"
  ct_hostname = "docker-dhcp"

  ct_operating_system_template_file_id = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  ct_operating_system_type             = "debian"

  ct_user_ssh_keys = [file("~/.ssh/id_ed25519.pub")]
}

output "docker_host_ssh" {
  value = module.docker_host.docker_host_ssh
}
```

**State 2 — Docker containers:**
```hcl
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "my-tf-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "docker" {
  host     = data.terraform_remote_state.infra.outputs.docker_host_ssh
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

module "my_app" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "my-app"
  image_name   = "my-app:latest"

  ports = [
    { internal = 8080, external = 8080 }
  ]
}
```

## Provider Configuration

The `ssh` and `time` providers require no configuration. The `proxmox` provider must be configured in your root module:

```hcl
provider "proxmox" {
  endpoint  = "https://your-proxmox-host:8006"
  api_token = var.proxmox_api_token
  insecure  = true  # Only for self-signed certificates
}
```

The `docker` provider (from `kreuzwerker/docker`) must be configured at the root level using this module's outputs or a known static IP:

```hcl
provider "docker" {
  host     = "ssh://root@<LXC_IP>:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}
```

## Notes

- Tags `tofu`, `ci`, and `docker` are automatically appended to user-provided tags
- Docker install script is always executed — there is no option to skip it
- Changing Docker configuration or the install script re-runs provisioning via SSH **without replacing the LXC** — all Docker workloads remain intact
- The Docker install script supports Debian and Ubuntu. Other distributions may require a custom `ct_additional_provisioner_script_content`
- For Docker provider SSH authentication, ensure your SSH key is both authorized on the LXC (`ct_user_ssh_keys`) and available in your local SSH agent
- Default `keyctl = true` and `nesting = true` are required for Docker in LXC — do not disable them
- Container must have SSH server installed and running in the OS template for provisioning to work
- For device passthrough, set `ct_unprivileged = false`

## Related Modules

- [`docker_service`](../../docker/service/) — Companion module for managing Docker containers on this host
