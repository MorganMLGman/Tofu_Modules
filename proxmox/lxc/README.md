# proxmox/lxc

One module for every Proxmox LXC in the homelab. It replaces `lxc_base`, `lxc_docker_host`, `lxc_docker_nvidia_host` and `lxc_ssh_provisioned`.

## What it does

- Creates the container (`bpg/proxmox`).
- Optionally installs Docker (`docker = {}`) and the NVIDIA driver + container toolkit (`nvidia = {...}`) over SSH.
- Optionally runs your own script (`ct_provisioner_script_content`) after them.
- Provisioning never replaces the container: scripts are idempotent and re-run when their content changes.

## MAC addresses

Unless an interface sets `mac_address`, its MAC is `BC:24:11:` plus the first 3 bytes of `md5("<hostname>/<interface name>")`.
It is known at plan time, so a DHCP reservation can be written before the first apply (no `-target` bootstrap):

```bash
tofu console <<< 'module.lxc_x.ct_mac_addresses'
```

Renaming the host or an interface changes the MAC. Pin `mac_address` where that matters.

## Usage

```hcl
module "lxc_app" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//proxmox/lxc?ref=<tag>"

  node_name   = "pve"
  ct_hostname = "lxc-app"

  ct_operating_system_template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  ct_operating_system_type             = "debian"

  ct_user_ssh_keys = local.ssh_keys
  docker           = {}
}

provider "docker" {
  host     = module.lxc_app.docker_host_ssh
  ssh_opts = module.lxc_app.docker_ssh_opts
}
```

GPU host (privileged container, driver must match the Proxmox host):

```hcl
  ct_unprivileged = false
  docker          = {}
  nvidia          = { driver_version = "580.142" }
```

## Features

| Input | Default | Effect |
|-------|---------|--------|
| `docker` | `null` | `{}` installs Docker CE; optional `install_compose`, `daemon_config`, `enable_tcp`, `tcp_port`; adds the `docker` tag |
| `nvidia` | `null` | Requires `docker` and `ct_unprivileged = false`; passes `devices` through, installs driver + toolkit; adds the `nvidia` tag |
| `ct_provisioner_script_content` | `""` | Extra script, runs after the installers |
| `ssh_host` | container IPv4 | Override when the address is known up front (e.g. a static lease) |

All other `ct_*` inputs are documented in [variables.tf](variables.tf).

## Outputs

`ct_id`, `ct_hostname`, `ct_ipv4_address`, `ct_ipv4_map`, `ct_status`, `ct_node_name`, `ct_mac_addresses`, `wait_complete`, `provisioner_result`, `docker_host_ssh`, `docker_host_tcp`, `docker_ssh_opts`.

## State migration

[moved.tf](moved.tf) moves resources out of the old wrappers' nested `module.lxc_base`, so switching `source` plans no container replacement. See [MIGRATION.md](../../MIGRATION.md) for the rest.

## Tests

`tofu test` (mock providers): MAC derivation, pinned MACs, provisioner toggling, NVIDIA preconditions.
