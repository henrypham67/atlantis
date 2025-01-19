# Ref: https://github.com/tomoki171923/terraform-aws/blob/79b88631f4c5f044d4b242398beb37760c960518/ssm/modules/iam/data.tf
locals {
  secrets = {
    ATLANTIS_REPO_ALLOWLIST = {
      value = var.ATLANTIS_REPO_ALLOWLIST
    }
    ATLANTIS_GH_USER = {
      value = var.ATLANTIS_GH_USER
    }
    ATLANTIS_GH_TOKEN = {
      secure_type = true
      value       = var.ATLANTIS_GH_TOKEN
    }
    ATLANTIS_GH_WEBHOOK_SECRET = {
      secure_type = true
      value       = var.ATLANTIS_GH_WEBHOOK_SECRET
    }
  }
}

module "ssm_parameters" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "1.1.2"

  for_each = local.secrets

  name        = each.key
  value       = try(each.value.value, null)
  secure_type = try(each.value.secure_type, null)
}
