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
  vpc_zone_identifier       = module.vpc.public_subnets
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  user_data     = <<-EOT
              #!/bin/bash
              LATEST_RELEASE=$(curl -s https://api.github.com/repos/runatlantis/atlantis/releases/latest | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4)
              curl -LO "$LATEST_RELEASE"
              sudo chmod +x atlantis
              sudo mv atlantis /usr/local/bin/
              EOT

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Use the ALB Module
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.13"

  name               = "atlantis-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_group.security_group_id]
  subnets            = module.vpc.public_subnets

  target_groups = {
    asg = {
      name              = "asg-tg"
      port              = 8080
      protocol          = "HTTP"
      vpc_id            = module.vpc.vpc_id
      create_attachment = false

      health_check = {
        enabled             = true
        port                = 8081
        interval            = 30
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200"
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
  }
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "asg"
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair" # The name of your key pair in AWS
  public_key = tls_private_key.my_key.public_key_openssh
}

# Output the private key to a file or screen
output "private_key" {
  value     = tls_private_key.my_key.private_key_pem
  sensitive = true
}

output "key_name" {
  value = aws_key_pair.my_key_pair.key_name
}