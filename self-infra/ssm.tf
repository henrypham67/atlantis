# Ref: https://github.com/tomoki171923/terraform-aws/blob/79b88631f4c5f044d4b242398beb37760c960518/ssm/modules/iam/data.tf

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
variable "ACCESS_KEY_ID" {
  sensitive = true
}
variable "SECRET_ACCESS_KEY" {
  sensitive = true
}

locals {
  secrets = {
    ATLANTIS_REPO_ALLOWLIST = {
      secure_type = true
      value = var.ATLANTIS_REPO_ALLOWLIST
    }
    ATLANTIS_GH_USER = {
      secure_type = true
      value = var.ATLANTIS_GH_USER
    }
    ATLANTIS_GH_TOKEN = {
      secure_type = true
      value = var.ATLANTIS_GH_TOKEN
    }
    ATLANTIS_GH_WEBHOOK_SECRET = {
      secure_type = true
      value = var.ATLANTIS_GH_WEBHOOK_SECRET
    }
    ACCESS_KEY_ID = {
      secure_type = true
      value = var.ACCESS_KEY_ID
    }
    SECRET_ACCESS_KEY = {
      secure_type = true
      value = var.SECRET_ACCESS_KEY
    }
  }
}

module "ssm_parameters" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.2"

  for_each = local.secrets

  name            = each.key
  value           = try(each.value.value, null)
  secure_type     = try(each.value.secure_type, null)
}