variable "service_name" {
  description = "Name of the Docker service. The container is named <service_name>_app unless container_name is set."
  type        = string
}

variable "container_name" {
  description = "Exact container name. null (default) means <service_name>_app. Set it to adopt an existing container without renaming it."
  type        = string
  default     = null
}

variable "image_name" {
  description = "Docker image name with tag (e.g. 'nginx:latest', 'redis:7-alpine')"
  type        = string
}

variable "volumes" {
  description = "Volume mappings. Each entry sets exactly one of host_path (bind mount) or volume_name (named volume, e.g. docker_volume.x.name)."
  type = list(object({
    container_path = string
    host_path      = optional(string)
    volume_name    = optional(string)
    read_only      = optional(bool, false)
  }))
  default = []

  validation {
    condition     = alltrue([for vol in var.volumes : (vol.host_path != null) != (vol.volume_name != null)])
    error_message = "Each volume needs exactly one of host_path or volume_name."
  }
}

variable "ports" {
  description = "List of port mappings"
  type = list(object({
    internal = number
    external = number
    protocol = optional(string, "tcp")
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables for the container (KEY=VALUE format)"
  type        = list(string)
  default     = []
}

variable "restart_policy" {
  description = "Restart policy for the container"
  type        = string
  default     = "unless-stopped"

  validation {
    condition     = contains(["no", "always", "unless-stopped", "on-failure"], var.restart_policy)
    error_message = "restart_policy must be one of: no, always, unless-stopped, on-failure."
  }
}

variable "networks" {
  description = "List of existing network names to attach the container to"
  type        = list(string)
  default     = []
}

variable "create_networks" {
  description = "List of Docker networks to create and attach to the container"
  type = list(object({
    name   = string
    driver = optional(string, "bridge")
    subnet = optional(string)
  }))
  default = []
}

variable "command" {
  description = "Override the default command for the container"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the container"
  type        = map(string)
  default     = {}
}

variable "devices" {
  description = "List of device mappings to expose to the container"
  type = list(object({
    host_path      = string
    container_path = optional(string)
    permissions    = optional(string, "rwm")
  }))
  default = []
}

variable "network_mode" {
  description = "Docker network mode (e.g. \"host\"). null leaves the default."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Container runtime (e.g. \"nvidia\"). null leaves the default."
  type        = string
  default     = null
}

variable "memory" {
  description = "Memory limit in MB. null means unlimited."
  type        = number
  default     = null
}

variable "capabilities_add" {
  description = "Linux capabilities to add (e.g. [\"CAP_NET_BIND_SERVICE\"])"
  type        = list(string)
  default     = []
}

variable "healthcheck" {
  description = "Container healthcheck. null means none."
  type = object({
    test         = list(string)
    interval     = string
    timeout      = string
    retries      = number
    start_period = optional(string)
  })
  default = null
}

variable "log_driver" {
  description = "Logging driver"
  type        = string
  default     = "json-file"
}

variable "log_opts" {
  description = "Logging driver options"
  type        = map(string)
  default = {
    "max-size" = "10m"
    "max-file" = "3"
  }
}
