variable "cf_domain" {
  description = "Cloudflare domain name"
  type        = string
  sensitive   = false
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

variable "cf_tunnel_id" {
  description = "Cloudflare tunnel ID"
  type        = string
  sensitive   = true
}

variable "services" {
  description = "List of services to expose"
  type = list(object({
    subdomain     = string
    service       = string
    no_tls_verify = optional(bool, false)
  }))
}

