# Tofu_Modules

Reusable OpenTofu modules for the homelab (Proxmox, Docker, Cloudflare, MikroTik). Directories are grouped by the provider they drive.

| Module | Purpose |
|--------|---------|
| [proxmox/lxc](proxmox/lxc/) | LXC container; optional Docker, NVIDIA GPU passthrough and SSH provisioning |
| [proxmox/vm_ci_qcow2](proxmox/vm_ci_qcow2/) | Cloud-init VM from a qcow2 image |
| [docker/service](docker/service/) | One Docker container, image pinned by digest |
| [docker/cloudflared](docker/cloudflared/) | Cloudflare tunnel + ingress + `cloudflared` container |
| [cloudflare/cloudflare_tunnel_ingress](cloudflare/cloudflare_tunnel_ingress/) | CNAMEs and ingress rules for an existing tunnel |
| [cloudflare/cloudflare_zero_trust_access_application](cloudflare/cloudflare_zero_trust_access_application/) | Access applications, policies and service tokens |
| [mikrotik/static_entries](mikrotik/static_entries/) | Static DHCP leases + DNS records |
| [mikrotik/port_forwarding](mikrotik/port_forwarding/) | DSTNAT rule, forward-chain accept, optional hairpin NAT |

Coming from the removed pre-GitHub modules (`lxc_base`, `lxc_docker_host`, `lxc_docker_nvidia_host`, `lxc_ssh_provisioned`, `docker_service`)? See [MIGRATION.md](MIGRATION.md).

## Two-layer docker workspaces

A host is split in two workspaces: the LXC layer (`proxmox/lxc`) and one `<name>_docker/` workspace per host for its containers, because the `docker` provider needs the host address that only exists after the LXC is created.

- **LXC layer:** export one object per container: `output "lxc_<name>" { value = module.lxc_<name>.connection }`.
- **Docker layer:** `scripts/new_docker_workspace.py <consumer-repo> <name> [port]` generates `_backend.tf`, `_providers.tf`, `_secrets.tf`, `_locals.tf` and `_outputs.tf` from [templates/docker_workspace](templates/docker_workspace/). Nothing else is passed in: the state backend is read from `<consumer-repo>/_backend.tf`, secret ids, domain and Cloudflare token key from the repo's existing `*_docker` workspaces. Whatever cannot be found is asked for (or taken from the environment, e.g. `CF_DOMAIN=...`).
- The same files are generated for every workspace, so they never drift. `local.lxc` is the container, `local.secrets` the app secrets plus `local.secrets.cloudflare`.

## Using a module

Always pin: `source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//<path>?ref=<tag>"`.
An unpinned source follows the default branch and changes under you on the next `tofu init -upgrade`.

Tag per module (`proxmox-lxc/v1.0.0`, `docker-cloudflared/v1.0.0`, ...) so a breaking change in one module does not force a version bump on consumers of another. Modules inside this repo reference each other by relative path, never by a git URL, so a tag always carries a consistent set.

## Checks

`scripts/check.sh` runs `tofu fmt -check`, `validate` for every module, and `tofu test` (mock providers, no credentials needed) where a module has `tests/`. The same script runs in CI on every push and pull request ([.github/workflows/ci.yaml](.github/workflows/ci.yaml)), against the minimum supported OpenTofu (1.11.2) and the latest release.
