# Cloudflare Zero Trust Access Application

OpenTofu module for managing Cloudflare Zero Trust Access applications with inline policies. Protects subdomains behind **identity-aware** authentication (humans, e.g. OIDC via Authelia) and/or **service-token** authentication (machine-to-machine, `non_identity`) — including both on the same hostname.

Access groups and identity providers are looked up by name via data sources — no need to hardcode UUIDs. Service tokens are created by this module and referenced from policies by name.

> **Note:** Each subdomain should be a separate application. Multi-domain applications in Cloudflare Access redirect to the primary domain after login, which causes issues with independent services.

> **Service tokens:** `client_secret` is only available at create/rotate time. After `tofu apply`, read it from the `service_token_secrets` output immediately. To rotate without downtime, bump `client_secret_version` (and optionally set `previous_client_secret_expires_at` for a grace window).

## Usage

### Human access (identity) — minimal with default policy

```hcl
module "access" {
  source = "path/to/cloudflare_zero_trust_access_application"

  cf_domain     = "example.com"
  cf_account_id = var.cf_account_id
  cf_zone_id    = var.cf_zone_id

  cf_allowed_idp_names = ["Authelia"]

  default_policy = {
    include = [{ group = "Authelia Access" }]
  }

  applications = [
    { subdomain = "z2m" },
    { subdomain = "ha" },
    { subdomain = "grafana" },
  ]
}
```

### Machine access (service token)

```hcl
module "access" {
  source = "path/to/cloudflare_zero_trust_access_application"

  cf_domain     = "example.com"
  cf_account_id = var.cf_account_id
  cf_zone_id    = var.cf_zone_id

  service_tokens = [
    { name = "ci-pipeline" },
  ]

  applications = [
    {
      subdomain = "api"
      policies = [{
        decision = "non_identity"
        include  = [{ service_token = "ci-pipeline" }]
      }]
    },
  ]
}
```

### Mixed — humans and machines on the same hostname

```hcl
module "access" {
  source = "path/to/cloudflare_zero_trust_access_application"

  cf_domain     = "example.com"
  cf_account_id = var.cf_account_id
  cf_zone_id    = var.cf_zone_id

  cf_allowed_idp_names = ["Authelia"]

  service_tokens = [
    { name = "automation", duration = "8760h" },
  ]

  applications = [
    {
      subdomain = "grafana"
      policies = [
        { decision = "allow", include = [{ group = "Authelia Access" }] },           # humans  (precedence 1)
        { decision = "non_identity", include = [{ service_token = "automation" }] },  # machines (precedence 2)
      ]
    },
  ]
}
```

## Variables

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `cf_domain` | `string` | yes | - | Cloudflare domain name |
| `cf_account_id` | `string` | yes | - | Cloudflare account ID (sensitive). Group/IdP lookups + service token scope |
| `cf_zone_id` | `string` | yes | - | Cloudflare zone ID (sensitive) |
| `cf_allowed_idp_names` | `list(string)` | no | `[]` | Default identity provider names. Empty = all IdPs allowed |
| `service_tokens` | `list(object)` | no | `[]` | Service tokens to create (see below) |
| `default_policy` | `object` | no | `null` | Default policy for applications without explicit policies |
| `applications` | `list(object)` | yes | - | List of access applications (see below) |

### Service token object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | yes | - | Token name; referenced from policy rules via `service_token` |
| `duration` | `string` | no | provider default | Token validity, e.g. `"8760h"` |
| `client_secret_version` | `number` | no | `null` | Bump to rotate the secret |
| `previous_client_secret_expires_at` | `string` | no | `null` | RFC3339; grace window for the old secret during rotation |

### Application object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `subdomain` | `string` | yes | - | Subdomain to protect (combined with `cf_domain`) |
| `name` | `string` | no | `"<subdomain>.<cf_domain>"` | Application name |
| `session_duration` | `string` | no | `"24h"` | Session token validity |
| `app_launcher_visible` | `bool` | no | `true` | Show in App Launcher (set `false` for pure machine apps) |
| `auto_redirect_to_identity` | `bool` | no | `true` | Skip IdP selection screen. Auto-forced to `false` for machine-only (`non_identity`) apps or when there is not exactly one effective IdP (Cloudflare requires exactly one) |
| `allowed_idp_names` | `list(string)` | no | `null` | Per-app IdP override |
| `policies` | `list(policy)` | no | `default_policy` | Access policies (uses default if omitted) |

### Policy object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | `string` | no | auto-generated | From first include rule's group / service token name |
| `decision` | `string` | no | `"allow"` | `"allow"`, `"deny"`, `"bypass"`, or `"non_identity"` (service tokens) |
| `precedence` | `number` | no | list order | Evaluation order; must be unique per app. If unset, auto-assigned from policy position (1, 2, 3…) |
| `include` | `list(rule)` | yes | - | OR-evaluated rules (match at least one) |
| `exclude` | `list(rule)` | no | `[]` | NOT-evaluated rules (must not match any) |
| `require` | `list(rule)` | no | `[]` | AND-evaluated rules (must match all) |

### Rule object

Each rule should have exactly **one** field set. Service-token rules belong in a `non_identity` policy; identity rules in an `allow`/`deny`/`bypass` policy.

| Field | Type | Description |
|-------|------|-------------|
| `group` | `string` | Access group name (resolved to ID via data source) |
| `email` | `string` | Specific email address |
| `email_domain` | `string` | Email domain (e.g., `"example.com"`) |
| `everyone` | `bool` | Match all users (set to `true`) |
| `ip` | `string` | IP address or CIDR range |
| `service_token` | `string` | Service token name (from `service_tokens`, resolved to ID) |
| `any_valid_service_token` | `bool` | Match any valid service token (set to `true`) |

## Outputs

| Name | Description |
|------|-------------|
| `applications` | Map of subdomains to `{ id, name, hostname }` |
| `group_ids` | Map of access group names to their resolved UUIDs |
| `service_token_client_ids` | Map of service token names to `{ id, client_id }` |
| `service_token_secrets` | Map of service token names to `client_secret` (**sensitive**) |
