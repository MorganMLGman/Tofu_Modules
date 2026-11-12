mock_provider "docker" {
  mock_data "docker_registry_image" {
    defaults = {
      sha256_digest = "sha256:abc123"
    }
  }
}

variables {
  name = "postgres:17"
}

run "image_is_pinned_by_digest" {
  command = plan

  assert {
    condition     = output.name == "postgres:17@sha256:abc123"
    error_message = "The image reference must carry the registry digest."
  }

  assert {
    condition     = docker_image.this.keep_locally == false
    error_message = "A superseded digest must be removed from the host."
  }
}
