data "scaleway_secret_version" "app" {
  secret_id = "@APP_SECRET_ID@"
  revision  = "latest"
}

data "scaleway_secret_version" "cloudflare" {
  secret_id = "@CLOUDFLARE_SECRET_ID@"
  revision  = "latest"
}

locals {
  secrets = merge(
    {
      for key, value in jsondecode(base64decode(data.scaleway_secret_version.app.data)) : key => sensitive(value)
    },
    {
      cloudflare = {
        for key, value in jsondecode(base64decode(data.scaleway_secret_version.cloudflare.data)) : key => sensitive(value)
      }
    }
  )
}
