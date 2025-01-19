module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.2"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role = true

  role_name = "atlantis-EC2SSMManaged"

  role_requires_mfa       = false
  create_instance_profile = true

  custom_role_policy_arns = [
    data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn,
    data.aws_iam_policy.CloudWatchAgentServerPolicy.arn,
    data.aws_iam_policy.AmazonSSMPatchAssociation.arn,
    data.aws_iam_policy.ReadOnlyAccess.arn,
    module.policy_kms_core.arn,
    module.policy_ssm_start_session.arn
  ]
}

### Policy

module "policy_kms_core" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name        = "atlantis_kms_core"
  path        = "/"
  description = "kms keys core permission."

  policy = data.template_file.kms_core.rendered
}

module "policy_ssm_start_session" {
  # remote module
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "atlantis_ssm_start_session_dev"
  path        = "/"
  description = "ssm start session policy for instances with develop tag."

  policy = data.template_file.ssm_start_session.rendered
}

data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}
data "aws_iam_policy" "CloudWatchAgentServerPolicy" {
  name = "CloudWatchAgentServerPolicy"
}
data "aws_iam_policy" "AmazonSSMPatchAssociation" {
  name = "AmazonSSMPatchAssociation"
}
data "aws_iam_policy" "ReadOnlyAccess" {
  name = "ReadOnlyAccess"
}

data "template_file" "ssm_start_session" {
  template = file("${path.module}/policies/ssm_start_session.json")
  vars = {
    aws_account     = data.aws_caller_identity.this.account_id
    aws_region      = data.aws_region.this.name
    environment_tag = "dev"
  }

}
data "template_file" "kms_core" {
  template = file("${path.module}/policies/kms_core.json")
  vars = {
    aws_account = data.aws_caller_identity.this.account_id
    aws_region  = data.aws_region.this.name
  }
}
