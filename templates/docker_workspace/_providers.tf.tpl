terraform {
  required_version = ">= 1.11.2"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~>2.65.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>5.15.0"
    }
  }
}

provider "scaleway" {
  region = "@SCW_REGION@"
}

# The LXC layer publishes one object per container: module.lxc_<name>.connection.
data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    profile                     = "@STATE_PROFILE@"
    bucket                      = "@STATE_BUCKET@"
    key                         = "@STATE_PREFIX@/terraform.tfstate"
    region                      = "@STATE_REGION@"
    skip_credentials_validation = true
    skip_region_validation      = true
    endpoints = {
      s3 = "@STATE_ENDPOINT@"
    }
  }
}

provider "docker" {
  host     = local.lxc.docker_host_ssh
  ssh_opts = local.lxc.docker_ssh_opts
}

provider "cloudflare" {
  api_token = local.secrets.cloudflare.@CF_API_TOKEN_KEY@
}
