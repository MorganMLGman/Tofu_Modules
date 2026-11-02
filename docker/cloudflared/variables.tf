variable "tunnel_name" {
  description = "Cloudflare tunnel name (e.g. tofu_myservice)"
  type        = string
}

variable "container_name" {
  description = "Name of the cloudflared Docker container"
  type        = string
  default     = "cloudflared"
}

variable "docker_network_name" {
  description = "Existing Docker network the cloudflared container joins. It must be able to resolve every service hostname in services."
  type        = string
}

variable "cf_domain" {
  description = "Cloudflare domain name"
  type        = string
}

variable "cf_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "cf_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

variable "services" {
  description = "Services exposed through the tunnel (one CNAME and ingress rule each)"
  type = list(object({
    subdomain     = string
    service       = string
    no_tls_verify = optional(bool, false)
  }))
}

variable "image_name" {
  description = "cloudflared image; pinned by registry digest on every plan"
  type        = string
  default     = "cloudflare/cloudflared:latest"
}
