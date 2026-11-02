terraform {
  required_version = ">= 1.11.2"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>5.15.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
