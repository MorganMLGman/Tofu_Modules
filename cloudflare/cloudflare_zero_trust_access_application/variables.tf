variable "cf_domain" {
  description = "Cloudflare domain name"
  type        = string
  sensitive   = false
}

variable "cf_account_id" {
  description = "Cloudflare account ID. Used for group/IdP lookups and for creating service tokens at account scope."
  type        = string
  sensitive   = true
}

variable "cf_zone_id" {
  description = "Cloudflare zone ID where the Access applications are created"
  type        = string
  sensitive   = true
}

variable "cf_allowed_idp_names" {
  description = "Default list of identity provider names to allow (looked up via data source). If empty, all IdPs are allowed. Irrelevant for non_identity (service token) policies."
  type        = list(string)
  default     = []
}

variable "service_tokens" {
  description = "Service tokens to create at account scope. Reference a token from a policy rule by its name. client_secret is only known at create/rotate time — bump client_secret_version to rotate."
  type = list(object({
    name                              = string
    duration                          = optional(string) # e.g. "8760h"; null = provider default
    client_secret_version             = optional(number) # bump to rotate the secret
    previous_client_secret_expires_at = optional(string) # RFC3339; grace window for the old secret
  }))
  default = []
}

variable "default_policy" {
  description = "Default policy applied to applications without explicit policies. Policy name is auto-generated from the first include rule (group or service_token) if not provided."
  type = object({
    name     = optional(string)
    decision = optional(string, "allow") # allow | deny | bypass | non_identity
    include = list(object({
      group                   = optional(string)
      email                   = optional(string)
      email_domain            = optional(string)
      everyone                = optional(bool)
      ip                      = optional(string)
      service_token           = optional(string) # service token name (from service_tokens)
      any_valid_service_token = optional(bool)
    }))
    exclude = optional(list(object({
      group                   = optional(string)
      email                   = optional(string)
      email_domain            = optional(string)
      everyone                = optional(bool)
      ip                      = optional(string)
      service_token           = optional(string)
      any_valid_service_token = optional(bool)
    })), [])
    require = optional(list(object({
      group                   = optional(string)
      email                   = optional(string)
      email_domain            = optional(string)
      everyone                = optional(bool)
      ip                      = optional(string)
      service_token           = optional(string)
      any_valid_service_token = optional(bool)
    })), [])
  })
  default = null
}

variable "applications" {
  description = "List of Zero Trust Access applications to create. Name is auto-generated from subdomain if not provided. Each app may carry multiple policies (e.g. an allow policy for humans and a non_identity policy for service tokens)."
  type = list(object({
    name                      = optional(string)
    subdomain                 = string
    session_duration          = optional(string, "24h")
    app_launcher_visible      = optional(bool, true)
    auto_redirect_to_identity = optional(bool, true)
    allowed_idp_names         = optional(list(string))
    policies = optional(list(object({
      name       = optional(string)
      decision   = optional(string, "allow") # allow | deny | bypass | non_identity
      precedence = optional(number)          # null = auto-assigned by list order (unique per app)
      include = list(object({
        group                   = optional(string)
        email                   = optional(string)
        email_domain            = optional(string)
        everyone                = optional(bool)
        ip                      = optional(string)
        service_token           = optional(string)
        any_valid_service_token = optional(bool)
      }))
      exclude = optional(list(object({
        group                   = optional(string)
        email                   = optional(string)
        email_domain            = optional(string)
        everyone                = optional(bool)
        ip                      = optional(string)
        service_token           = optional(string)
        any_valid_service_token = optional(bool)
      })), [])
      require = optional(list(object({
        group                   = optional(string)
        email                   = optional(string)
        email_domain            = optional(string)
        everyone                = optional(bool)
        ip                      = optional(string)
        service_token           = optional(string)
        any_valid_service_token = optional(bool)
      })), [])
    })))
  }))
}
