variable "ATLANTIS_REPO_ALLOWLIST" {
  sensitive = true
}
variable "ATLANTIS_GH_USER" {
  sensitive = true
}
variable "ATLANTIS_GH_TOKEN" {
  sensitive = true
}
variable "ATLANTIS_GH_WEBHOOK_SECRET" {
  sensitive = true
}
variable "region" {
  default = "us-east-1"
}