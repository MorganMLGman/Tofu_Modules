locals {
  lxc       = data.terraform_remote_state.infra.outputs.lxc_@NAME@
  cf_domain = "@CF_DOMAIN@"
}
