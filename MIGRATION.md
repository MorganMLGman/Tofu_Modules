# Migration

Nothing here has been applied to any consumer. Every step below ends with `tofu plan`; do not apply unless it shows no unexpected replacement.

Coming from the pre-GitHub modules (`lxc_base`, `lxc_docker_host`, `lxc_docker_nvidia_host`, `lxc_ssh_provisioned`, `docker_service`, `cloudflare_tunnel_simple`)? They are gone from this repository; the old tags (v1.0.0 ... v3.0.0) only exist on the previous Codeberg remote, which consumers still pinned to them must keep using.

## Old module -> `proxmox/lxc`

1. **Before changing `source`**, read the current MAC of each container: `tofu console <<< 'module.lxc_x.ct_mac_addresses'`. MACs are now derived from the hostname, so a container that did not pin `mac_address` would get a different one (and lose its DHCP lease). Put the printed value in `ct_network_interfaces[].mac_address`.
2. Change `source` to `proxmox/lxc?ref=<tag>`.
3. Rename inputs:

| Old | New |
|-----|-----|
| `docker_install_compose`, `docker_daemon_config`, `docker_enable_tcp`, `docker_tcp_port` | `docker = { install_compose, daemon_config, enable_tcp, tcp_port }` (`docker = {}` for defaults) |
| `nvidia_driver_version`, `nvidia_devices` | `nvidia = { driver_version, devices }` (also set `ct_unprivileged = false`) |
| `ct_additional_provisioner_script_content` | `ct_provisioner_script_content` |
| `ct_extra_tags` | removed (`docker` / `nvidia` tags are added automatically) |
| `replace_trigger_value` | removed (a changed script never replaces the container) |

4. Outputs: `lxc_ipv4_map` -> `ct_ipv4_map`, `docker_install_result` -> `provisioner_result`. `docker_host_ssh`, `docker_ssh_opts`, `ct_mac_addresses` are unchanged.
5. `tofu plan`. The container and `time_sleep` are moved by [moved.tf](proxmox/lxc/moved.tf). Expected leftovers: `random_id.mac` and `terraform_data.replace_trigger` are destroyed (harmless); the provisioner script uploads to `/tmp/provisioner.sh` instead of `/tmp/docker_install.sh` and re-runs once (idempotent).

A consumer that used `lxc_base` (or `lxc_ssh_provisioned`) plus a hand-written `ssh_resource` can keep it, or move the script into `ct_provisioner_script_content` (use `ssh_host` when the address comes from a static lease).

## `docker_service` -> `docker/service`

Path changed. `pull_triggers_enabled` is gone: the image is always pinned by digest and the container follows `image_id`. The first plan replaces the image and the container once.

## Per-workspace Cloudflare tunnel -> `docker/cloudflared`

The tunnel, secret, token, ingress and `cloudflared` container resources move into the module. In the caller add `moved` blocks from the old root addresses (`cloudflare_zero_trust_tunnel_cloudflared.x`, `random_bytes.tunnel_secret`, `docker_container.cloudflared`, ...) to `module.cloudflared.*`. A workspace whose secret is a `random_id` (pingvin) would get a new `random_bytes` secret, which replaces the tunnel: keep its tunnel resources as they are until that is decided.
