# docker_service - Terraform Module for Docker Container Management

Terraform/OpenTofu module for managing Docker containers using the `kreuzwerker/docker` provider. Designed as a companion to `proxmox/lxc` but can be used with any Docker host.

## Description

This module manages individual Docker containers with:
- Automatic image pulling with SHA256 digest tracking for updates
- Container replacement when image updates are detected
- Dynamic volume, port, network, and environment variable configuration
- Optional Docker network creation and attachment
- Container labeling support

## Requirements

- OpenTofu >= 1.11.2 / Terraform >= 1.11.2
- Docker host accessible via the configured `kreuzwerker/docker` provider
- Provider:
  - `kreuzwerker/docker` ~> 3.6

## Inputs (Variables)

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `service_name` | `string` | Service name; the container is named `<service_name>_app` unless `container_name` is set |
| `image_name` | `string` | Docker image with tag (e.g. `nginx:latest`) |

### Optional

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `container_name` | `string` | `null` | Exact container name (adopt an existing container without renaming it) |
| `volumes` | `list(object)` | `[]` | Mounts: `container_path` plus exactly one of `host_path` (bind) or `volume_name` (named volume, e.g. `docker_volume.x.name`), optional `read_only` |
| `healthcheck` | `object` | `null` | `test`, `interval`, `timeout`, `retries`, optional `start_period` |
| `network_mode` | `string` | `null` | e.g. `"host"` |
| `runtime` | `string` | `null` | e.g. `"nvidia"` |
| `memory` | `number` | `null` | Memory limit in MB |
| `capabilities_add` | `list(string)` | `[]` | Linux capabilities to add |
| `log_driver`, `log_opts` | `string`, `map(string)` | `json-file`, `max-size=10m` / `max-file=3` | Logging; the default is the one every container in the homelab already uses |
| `ports` | `list(object)` | `[]` | Port mappings (internal, external, protocol) |
| `environment_variables` | `list(string)` | `[]` | Environment variables in KEY=VALUE format |
| `restart_policy` | `string` | `"unless-stopped"` | Restart policy (no, always, unless-stopped, on-failure) |
| `networks` | `list(string)` | `[]` | Existing network names to attach to |
| `create_networks` | `list(object)` | `[]` | Networks to create and attach (name, driver, subnet) |
| `command` | `list(string)` | `[]` | Override container command |
| `labels` | `map(string)` | `{}` | Container labels |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `container_id` | `string` | Docker container ID |
| `container_name` | `string` | Docker container name |
| `image_id` | `string` | Docker image ID |
| `image_name` | `string` | Docker image name |
| `network_ids` | `map(string)` | Map of created network names to IDs |

## Usage Examples

### Basic Container

```hcl
module "nginx" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "nginx"
  image_name   = "nginx:latest"

  ports = [
    { internal = 80, external = 8080 }
  ]
}
```

### Container with Volumes and Environment Variables

```hcl
module "postgres" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "postgres"
  image_name   = "postgres:16-alpine"

  ports = [
    { internal = 5432, external = 5432 }
  ]

  volumes = [
    {
      host_path      = "/mnt/docker-volumes/postgres/data"
      container_path = "/var/lib/postgresql/data"
    }
  ]

  environment_variables = [
    "POSTGRES_DB=myapp",
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=secret"
  ]
}
```

### Container with Network Creation

```hcl
module "app" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "my-app"
  image_name   = "my-app:latest"

  ports = [
    { internal = 8080, external = 8080 }
  ]

  create_networks = [
    {
      name   = "app-network"
      driver = "bridge"
      subnet = "172.20.0.0/16"
    }
  ]

  labels = {
    "com.example.description" = "My Application"
    "com.example.environment" = "production"
  }
}
```

### Container Attached to Existing Networks

```hcl
module "backend" {
  source = "git::ssh://git@github.com/MorganMLGman/Tofu_Modules.git//docker/service?ref=<tag>"

  service_name = "backend"
  image_name   = "backend:latest"

  networks = ["app-network", "db-network"]

  environment_variables = [
    "DATABASE_URL=postgres://admin:secret@postgres_app:5432/myapp"
  ]
}
```

## Provider Configuration

The Docker provider must be configured at the root level:

```hcl
# SSH connection (recommended with proxmox/lxc)
provider "docker" {
  host     = "ssh://root@192.168.1.100:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

# Or TCP connection
provider "docker" {
  host = "tcp://192.168.1.100:2376"
}

# Or local Docker socket
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```

## Notes

- The image is resolved through [`docker/image`](../image/), so it is always pinned by digest.
- To adopt an existing container, set `container_name` to its current name and add `moved { from = docker_container.x  to = module.x.docker_container.service_container }` (and for its image `from = docker_image.x  to = module.x.module.image.docker_image.this`). A container that referenced its image by `.name` instead of `.image_id` is replaced by the move, because the `image` attribute changes from the reference to the image ID.

- Container is named `${service_name}_app`
- The image is pinned by registry digest on every plan; a new digest pulls the image and recreates the container
- Volume host directories are auto-created by Docker on first use
- Networks listed in `create_networks` are created and attached; networks listed in `networks` must already exist
- Use `depends_on = [module.docker_host]` when used with `proxmox/lxc` to ensure the Docker host is ready

## Related Modules

- [`proxmox/lxc`](../../proxmox/lxc/) — Creates a Proxmox LXC container with Docker CE pre-installed (`docker = {}`)
