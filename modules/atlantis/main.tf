data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # Match Amazon Linux 2 AMI names
  }

  owners = ["amazon"] # Amazon Linux AMIs are owned by Amazon
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.1"

  name                      = "atlantis-asg"
  vpc_zone_identifier       = var.subnets
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300

  image_id                  = data.aws_ami.amazon_linux.id
  instance_type             = "t3.micro"
  iam_instance_profile_name = module.iam_role.iam_instance_profile_name
  user_data                 = base64encode(file("${path.module}/script/init.sh"))


  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [module.security_group.security_group_id]
      associate_public_ip_address = true
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_cloudwatch_log_group" "asg_ec2_logs" {
  name              = "asg-ec2-log-group"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "asg_ec2_ssm_logs" {
  name              = "asg-ec2-ssm-log-group"
  retention_in_days = 7
}
