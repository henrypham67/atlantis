variable "ATLANTIS_REPO_ALLOWLIST" {
}
variable "ATLANTIS_GH_USER" {
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
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = list(string)
}
variable "instance_type" {
  default = "t3.micro"
}