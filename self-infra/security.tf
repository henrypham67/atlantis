
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.2"

  name        = "atlantis-sg"
  description = "Security group for Atlantis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["http-8080-tcp", "https-443-tcp"]
  egress_rules  = ["all-all"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}