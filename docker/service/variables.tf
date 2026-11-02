variable "service_name" {
  description = "Name of the Docker service (used for container naming and volume paths)"
  type        = string
}

variable "image_name" {
  description = "Docker image name with tag (e.g. 'nginx:latest', 'redis:7-alpine')"
  type        = string
}

variable "volumes" {
  description = "List of volume mappings"
  type = list(object({
    host_path      = string
    container_path = string
    read_only      = optional(bool, false)
  }))
  default = []
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
