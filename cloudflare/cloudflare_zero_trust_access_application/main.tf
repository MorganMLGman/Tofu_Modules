# --- Locals ---

locals {
  # Auto-generate the default policy name from the first include rule (group, then service token)
  default_policy_name = var.default_policy != null ? coalesce(
    var.default_policy.name,
    try("${lower(replace(var.default_policy.include[0].group, " ", "_"))}_policy", null),
    try("${lower(replace(var.default_policy.include[0].service_token, " ", "_"))}_token_policy", null),
    "default_access_policy"
  ) : null

  # Resolve the default policy into the per-app policy shape
  resolved_default_policy = var.default_policy != null ? {
    name       = local.default_policy_name
    decision   = var.default_policy.decision
    precedence = 1
    include    = var.default_policy.include
    exclude    = var.default_policy.exclude
    require    = var.default_policy.require
  } : null

  # Resolve applications: fill in defaults for name and policies
  resolved_applications = [
    for app in var.applications : {
      name                      = coalesce(app.name, "${app.subdomain}.${var.cf_domain}")
      subdomain                 = app.subdomain
      session_duration          = app.session_duration
      app_launcher_visible      = app.app_launcher_visible
      auto_redirect_to_identity = app.auto_redirect_to_identity
      allowed_idp_names         = app.allowed_idp_names
      policies = app.policies != null ? [
        for idx, policy in app.policies : {
          name = coalesce(
            policy.name,
            try("${lower(replace(policy.include[0].group, " ", "_"))}_policy", null),
            try("${lower(replace(policy.include[0].service_token, " ", "_"))}_token_policy", null),
            "${app.subdomain}_policy"
          )
          decision = policy.decision
          # Auto-assign precedence by list order if unset (must be unique per app)
          precedence = coalesce(policy.precedence, idx + 1)
          include    = policy.include
          exclude    = policy.exclude
          require    = policy.require
        }
      ] : local.resolved_default_policy != null ? [local.resolved_default_policy] : []
    }
  ]

  # Collect unique group names from all resolved policies (for data source lookup)
  all_group_names = toset(flatten([
    for app in local.resolved_applications : flatten([
      for policy in app.policies : concat(
        [for rule in policy.include : rule.group if rule.group != null],
        [for rule in policy.exclude : rule.group if rule.group != null],
        [for rule in policy.require : rule.group if rule.group != null],
      )
    ])
  ]))

  group_ids = {
    for name, data_source in data.cloudflare_zero_trust_access_groups.by_name :
    name => data_source.result[0].id
  }

  idp_ids = {
    for idp in data.cloudflare_zero_trust_access_identity_providers.all.result :
    idp.name => idp.id
  }

  resolved_default_idp_ids = [
    for name in var.cf_allowed_idp_names : local.idp_ids[name]
  ]

  # Effective IdP names per app: explicit per-app > global default > all account IdPs
  effective_idp_names = {
    for app in local.resolved_applications : app.subdomain => (
      length(coalesce(app.allowed_idp_names, [])) > 0 ? app.allowed_idp_names :
      length(var.cf_allowed_idp_names) > 0 ? var.cf_allowed_idp_names :
      keys(local.idp_ids)
    )
  }

  app_has_identity_policy = {
    for app in local.resolved_applications : app.subdomain =>
    length([for p in app.policies : p if p.decision != "non_identity"]) > 0
  }

  # auto_redirect_to_identity is only valid with an identity policy AND exactly one IdP;
  # force false for machine-only apps or multi/zero-IdP apps to avoid a Cloudflare API error.
  app_auto_redirect = {
    for app in local.resolved_applications : app.subdomain => (
      app.auto_redirect_to_identity
      && local.app_has_identity_policy[app.subdomain]
      && length(local.effective_idp_names[app.subdomain]) == 1
    )
  }
}

# --- Data Sources ---

data "cloudflare_zero_trust_access_groups" "by_name" {
  for_each   = local.all_group_names
  account_id = var.cf_account_id
  name       = each.value

  lifecycle {
    postcondition {
      condition     = length(self.result) > 0
      error_message = "No Cloudflare Access group named \"${each.value}\" found in this account. Create the group or fix the policy rule."
    }
  }
}

data "cloudflare_zero_trust_access_identity_providers" "all" {
  account_id = var.cf_account_id
}

# --- Service Tokens ---

resource "cloudflare_zero_trust_access_service_token" "token" {
  for_each = { for t in var.service_tokens : t.name => t }

  account_id                        = var.cf_account_id
  name                              = each.value.name
  duration                          = each.value.duration
  client_secret_version             = each.value.client_secret_version
  previous_client_secret_expires_at = each.value.previous_client_secret_expires_at
}

# --- Access Applications ---

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = { for app in local.resolved_applications : app.subdomain => app }

  zone_id          = var.cf_zone_id
  name             = each.value.name
  type             = "self_hosted"
  session_duration = each.value.session_duration

  destinations = [{
    type = "public"
    uri  = "${each.value.subdomain}.${var.cf_domain}"
  }]

  app_launcher_visible      = each.value.app_launcher_visible
  auto_redirect_to_identity = local.app_auto_redirect[each.key]

  allowed_idps = length(coalesce(each.value.allowed_idp_names, [])) > 0 ? [
    for name in each.value.allowed_idp_names : local.idp_ids[name]
  ] : length(var.cf_allowed_idp_names) > 0 ? local.resolved_default_idp_ids : null

  policies = [
    for policy in each.value.policies : {
      name       = policy.name
      decision   = policy.decision
      precedence = policy.precedence

      include = [
        for rule in policy.include : merge(
          rule.group != null ? { group = { id = local.group_ids[rule.group] } } : {},
          rule.email != null ? { email = { email = rule.email } } : {},
          rule.email_domain != null ? { email_domain = { domain = rule.email_domain } } : {},
          rule.everyone == true ? { everyone = {} } : {},
          rule.ip != null ? { ip = { ip = rule.ip } } : {},
          rule.service_token != null ? { service_token = { token_id = cloudflare_zero_trust_access_service_token.token[rule.service_token].id } } : {},
          rule.any_valid_service_token == true ? { any_valid_service_token = {} } : {},
        )
      ]

      exclude = [
        for rule in policy.exclude : merge(
          rule.group != null ? { group = { id = local.group_ids[rule.group] } } : {},
          rule.email != null ? { email = { email = rule.email } } : {},
          rule.email_domain != null ? { email_domain = { domain = rule.email_domain } } : {},
          rule.everyone == true ? { everyone = {} } : {},
          rule.ip != null ? { ip = { ip = rule.ip } } : {},
          rule.service_token != null ? { service_token = { token_id = cloudflare_zero_trust_access_service_token.token[rule.service_token].id } } : {},
          rule.any_valid_service_token == true ? { any_valid_service_token = {} } : {},
        )
      ]

      require = [
        for rule in policy.require : merge(
          rule.group != null ? { group = { id = local.group_ids[rule.group] } } : {},
          rule.email != null ? { email = { email = rule.email } } : {},
          rule.email_domain != null ? { email_domain = { domain = rule.email_domain } } : {},
          rule.everyone == true ? { everyone = {} } : {},
          rule.ip != null ? { ip = { ip = rule.ip } } : {},
          rule.service_token != null ? { service_token = { token_id = cloudflare_zero_trust_access_service_token.token[rule.service_token].id } } : {},
          rule.any_valid_service_token == true ? { any_valid_service_token = {} } : {},
        )
      ]
    }
  ]
}
