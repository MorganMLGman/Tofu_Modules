mock_provider "docker" {
  mock_data "docker_registry_image" {
    defaults = {
      sha256_digest = "sha256:abc123"
    }
  }
}

variables {
  service_name = "web"
  image_name   = "nginx:1.27"
}

run "image_is_pinned_by_digest" {
  command = plan

  assert {
    condition     = docker_image.service_image.name == "nginx:1.27@sha256:abc123"
    error_message = "The image must be pinned by registry digest."
  }

  assert {
    condition     = docker_container.service_container.name == "web_app"
    error_message = "Container name must be <service_name>_app."
  }
}

run "created_and_existing_networks_are_both_attached" {
  command = plan

  variables {
    networks        = ["existing"]
    create_networks = [{ name = "fresh", subnet = "172.30.0.0/24" }]
  }

  assert {
    condition     = length(docker_container.service_container.networks_advanced) == 2
    error_message = "Container must join both the existing and the created network."
  }

  assert {
    condition     = length(docker_network.service_network) == 1
    error_message = "Only create_networks entries are created."
  }
}

run "invalid_restart_policy_is_rejected" {
  command = plan

  variables {
    restart_policy = "sometimes"
  }

  expect_failures = [var.restart_policy]
}
