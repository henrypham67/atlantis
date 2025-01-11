module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.17.0"

  name                 = "atlantis-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.2"

  name        = "atlantis-sg"
  description = "Security group for Atlantis"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = ["http-80-tcp", "ssh-tcp"]
  egress_rules  = ["all-all"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}