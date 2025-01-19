# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.17.0"

#   name                 = "atlantis-vpc"
#   cidr                 = "10.0.0.0/16"
#   azs                  = ["us-east-1a", "us-east-1b"]
#   public_subnets       = ["10.0.1.0/24"]
#   enable_dns_support   = true
#   enable_dns_hostnames = true
# }



# module "atlantis" {
#   source = "../../modules/atlantis"

#   ATLANTIS_REPO_ALLOWLIST = var.ATLANTIS_REPO_ALLOWLIST
#   ATLANTIS_GH_USER = var.ATLANTIS_GH_USER
#   ATLANTIS_GH_TOKEN = var.ATLANTIS_GH_TOKEN
#   ATLANTIS_GH_WEBHOOK_SECRET = var.ATLANTIS_GH_WEBHOOK_SECRET
#   region = var.region
#   vpc_id = module.vpc.module.vpc.vpc_id
#   subnets = module.vpc.public_subnets
# }


module "atlantis" {
  source = "../../modules/atlantis"

  ATLANTIS_REPO_ALLOWLIST = var.ATLANTIS_REPO_ALLOWLIST
  ATLANTIS_GH_USER = var.ATLANTIS_GH_USER
  ATLANTIS_GH_TOKEN = var.ATLANTIS_GH_TOKEN
  ATLANTIS_GH_WEBHOOK_SECRET = var.ATLANTIS_GH_WEBHOOK_SECRET
  region = var.region
  vpc_id = var.vpc_id
  subnets = var.subnets
}
