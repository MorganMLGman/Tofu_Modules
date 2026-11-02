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
    condition     = output.image_name == "nginx:1.27@sha256:abc123"
    error_message = "The image must be pinned by registry digest."
  }
}

run "container_name_defaults_to_service_name_app" {
  command = plan

  assert {
    condition     = docker_container.service_container.name == "web_app"
    error_message = "Container name must default to <service_name>_app."
  }
}

run "explicit_container_name_wins" {
  command = plan

  variables {
    container_name = "my-web"
  }

  assert {
    condition     = docker_container.service_container.name == "my-web"
    error_message = "container_name must be used verbatim."
  }
}

run "standard_log_block_is_the_default" {
  command = plan

  assert {
    condition     = docker_container.service_container.log_driver == "json-file" && docker_container.service_container.log_opts == tomap({ "max-size" = "10m", "max-file" = "3" })
    error_message = "Containers must log json-file 10m x 3 unless told otherwise."
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

run "bind_mounts_and_named_volumes_both_work" {
  command = plan

  variables {
    volumes = [
      { container_path = "/data", volume_name = "web_data" },
      { container_path = "/etc/conf", host_path = "/srv/conf", read_only = true },
    ]
  }

  assert {
    condition     = length(docker_container.service_container.volumes) == 2
    error_message = "Both volume kinds must be mounted."
  }

  assert {
    condition     = anytrue([for v in docker_container.service_container.volumes : v.volume_name == "web_data" && v.container_path == "/data"]) && anytrue([for v in docker_container.service_container.volumes : v.host_path == "/srv/conf" && v.read_only == true])
    error_message = "volume_name and host_path must each reach the right mount."
  }
}

run "a_volume_needs_exactly_one_source" {
  command = plan

  variables {
    volumes = [{ container_path = "/data", volume_name = "a", host_path = "/b" }]
  }

  expect_failures = [var.volumes]
}

run "host_network_runtime_memory_and_capabilities" {
  command = plan

  variables {
    network_mode     = "host"
    runtime          = "nvidia"
    memory           = 1000
    capabilities_add = ["CAP_NET_BIND_SERVICE"]
  }

  assert {
    condition     = docker_container.service_container.network_mode == "host" && docker_container.service_container.runtime == "nvidia" && docker_container.service_container.memory == 1000
    error_message = "network_mode, runtime and memory must reach the container."
  }

  assert {
    condition     = one(docker_container.service_container.capabilities).add == toset(["CAP_NET_BIND_SERVICE"])
    error_message = "capabilities_add must reach the container."
  }
}

run "healthcheck_is_passed_through" {
  command = plan

  variables {
    healthcheck = {
      test         = ["CMD", "true"]
      interval     = "30s"
      timeout      = "20s"
      retries      = 3
      start_period = "10s"
    }
  }

  assert {
    condition     = one(docker_container.service_container.healthcheck).start_period == "10s" && one(docker_container.service_container.healthcheck).retries == 3
    error_message = "healthcheck fields must reach the container."
  }
}

run "invalid_restart_policy_is_rejected" {
  command = plan

  variables {
    restart_policy = "sometimes"
  }

  expect_failures = [var.restart_policy]
}
