mock_provider "cloudflare" {
  mock_data "cloudflare_zero_trust_access_groups" {
    defaults = {
      result = [{
        id         = "group-id"
        name       = "group"
        is_default = []
        include    = []
        exclude    = []
        require    = []
      }]
    }
  }

  mock_data "cloudflare_zero_trust_access_identity_providers" {
    defaults = {
      result = [{
        id   = "idp-id"
        name = "authelia"
        type = "oidc"
        config = {
          apps_domain                = null
          attributes                 = null
          auth_url                   = null
          authorization_server_id    = null
          centrify_account           = null
          centrify_app_id            = null
          certs_url                  = null
          claims                     = null
          client_id                  = null
          client_secret              = null
          conditional_access_enabled = null
          directory_id               = null
          email_attribute_name       = null
          email_claim_name           = null
          header_attributes          = null
          idp_public_certs           = null
          issuer_url                 = null
          okta_account               = null
          onelogin_account           = null
          ping_env_id                = null
          pkce_enabled               = null
          prompt                     = null
          scopes                     = null
          sign_request               = null
          sso_target_url             = null
          support_groups             = null
          token_url                  = null
        }
        scim_config = {
          enabled                  = false
          identity_update_behavior = "automatic"
          scim_base_url            = ""
          seat_deprovision         = false
          secret                   = ""
          user_deprovision         = false
        }
      }]
    }
  }
}

variables {
  cf_domain     = "example.com"
  cf_account_id = "acc"
  cf_zone_id    = "zone"
}

run "default_policy_name_comes_from_first_group" {
  command = plan

  variables {
    default_policy = { include = [{ group = "Home Admins" }] }
    applications   = [{ subdomain = "app" }]
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.app["app"].policies[0].name == "home_admins_policy"
    error_message = "Default policy name must be derived from the first group."
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.app["app"].name == "app.example.com"
    error_message = "Application name must default to subdomain.cf_domain."
  }
}

run "precedence_follows_list_order" {
  command = plan

  variables {
    applications = [{
      subdomain = "app"
      policies = [
        { include = [{ group = "A" }] },
        { include = [{ group = "B" }] },
        { include = [{ group = "C" }], precedence = 10 },
      ]
    }]
  }

  assert {
    condition     = [for p in cloudflare_zero_trust_access_application.app["app"].policies : p.precedence] == [1, 2, 10]
    error_message = "Unset precedence must follow list position; an explicit one must win."
  }
}

run "auto_redirect_needs_identity_policy_and_single_idp" {
  command = plan

  variables {
    applications = [
      { subdomain = "human", policies = [{ include = [{ email_domain = "example.com" }] }] },
      { subdomain = "machine", policies = [{ decision = "non_identity", include = [{ any_valid_service_token = true }] }] },
    ]
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.app["human"].auto_redirect_to_identity == true
    error_message = "One IdP and an identity policy: auto redirect stays on."
  }

  assert {
    condition     = cloudflare_zero_trust_access_application.app["machine"].auto_redirect_to_identity == false
    error_message = "A non_identity-only app must not auto redirect (Cloudflare rejects it)."
  }
}

run "unknown_group_fails_with_clear_error" {
  command = plan

  variables {
    applications = [{ subdomain = "app", policies = [{ include = [{ group = "ghost" }] }] }]
  }

  override_data {
    target = data.cloudflare_zero_trust_access_groups.by_name
    values = { result = [] }
  }

  expect_failures = [data.cloudflare_zero_trust_access_groups.by_name]
}
