output "container_id" {
  description = "The ID of the created Docker container"
  value       = docker_container.service_container.id
}

output "container_name" {
  description = "The name of the created Docker container"
  value       = docker_container.service_container.name
}

output "image_id" {
  description = "The ID of the Docker image"
  value       = module.image.image_id
}

output "image_name" {
  description = "The name of the Docker image"
  value       = module.image.name
}

output "network_ids" {
  description = "Map of created network names to their IDs"
  value       = { for name, net in docker_network.service_network : name => net.id }
}
