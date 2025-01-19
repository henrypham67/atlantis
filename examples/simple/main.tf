locals {
  ATLANTIS_REPO_ALLOWLIST    = "github.com/henrypham67/atlantis"
  ATLANTIS_GH_USER           = "henrypham67"
  ATLANTIS_GH_TOKEN          = ""
  ATLANTIS_GH_WEBHOOK_SECRET = ""
  region                     = "us-east-1"
  vpc_id                     = ""   # module.vpc.vpc_id
  subnets                    = [""] # module.vpc.public_subnets
}


module "atlantis" {
  source = "../../modules/atlantis"

  ATLANTIS_REPO_ALLOWLIST    = local.ATLANTIS_REPO_ALLOWLIST
  ATLANTIS_GH_USER           = local.ATLANTIS_GH_USER
  ATLANTIS_GH_TOKEN          = local.ATLANTIS_GH_TOKEN
  ATLANTIS_GH_WEBHOOK_SECRET = local.ATLANTIS_GH_WEBHOOK_SECRET
  region                     = local.region
  vpc_id                     = local.vpc_id
  subnets                    = local.subnets
}
