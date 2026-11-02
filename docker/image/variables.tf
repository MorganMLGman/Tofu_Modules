variable "name" {
  description = "Image reference with a tag, e.g. \"postgres:17\" or \"ghcr.io/org/app:daily\". Resolved to its registry digest on every plan."
  type        = string
}
