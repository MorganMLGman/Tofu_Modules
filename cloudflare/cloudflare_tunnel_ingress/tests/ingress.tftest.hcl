mock_provider "cloudflare" {}

variables {
  cf_domain     = "example.com"
  cf_account_id = "acc"
  cf_zone_id    = "zone"
  cf_tunnel_id  = "tunnel"
}

run "one_cname_and_rule_per_service_plus_catch_all" {
  command = plan

  variables {
    services = [
      { subdomain = "a", service = "http://a:80" },
      { subdomain = "b", service = "https://b:443", no_tls_verify = true },
    ]
  }

  assert {
    condition     = length(cloudflare_dns_record.dns_record) == 2
    error_message = "Expected one CNAME per service."
  }

  assert {
    condition     = length(cloudflare_zero_trust_tunnel_cloudflared_config.config.config.ingress) == 3
    error_message = "Expected one rule per service plus the 404 catch-all."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.config.config.ingress[2].service == "http_status:404"
    error_message = "The catch-all rule must come last."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.config.config.ingress[0].hostname == "a.example.com"
    error_message = "Hostname must be subdomain.cf_domain."
  }
}

run "no_tls_verify_only_when_requested" {
  command = plan

  variables {
    services = [
      { subdomain = "a", service = "http://a:80" },
      { subdomain = "b", service = "https://b:443", no_tls_verify = true },
    ]
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.config.config.ingress[0].origin_request == null
    error_message = "origin_request must be unset by default."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.config.config.ingress[1].origin_request.no_tls_verify == true
    error_message = "no_tls_verify must reach origin_request."
  }
}
