data "docker_registry_image" "this" {
  name = var.name
}

# Pinned by digest: with a bare tag plus pull_triggers the provider updates state but never re-pulls,
# so image_id goes stale and containers using the image are not recreated.
resource "docker_image" "this" {
  name         = "${data.docker_registry_image.this.name}@${data.docker_registry_image.this.sha256_digest}"
  keep_locally = true
}
