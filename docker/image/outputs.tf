output "image_id" {
  description = "Image ID. Use it as a container's image so the container is recreated whenever the digest changes."
  value       = docker_image.this.image_id
}

output "name" {
  description = "Digest-pinned reference (name:tag@sha256:...). Use it instead of image_id only where a container already references the image by name, to avoid a replacement."
  value       = docker_image.this.name
}
