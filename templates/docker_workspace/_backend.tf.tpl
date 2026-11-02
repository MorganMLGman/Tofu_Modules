terraform {
  backend "s3" {
    profile                     = "@STATE_PROFILE@"
    bucket                      = "@STATE_BUCKET@"
    key                         = "@STATE_PREFIX@/@NAME@_docker/terraform.tfstate"
    region                      = "@STATE_REGION@"
    skip_credentials_validation = true
    skip_region_validation      = true
    endpoints = {
      s3 = "@STATE_ENDPOINT@"
    }
  }
}
