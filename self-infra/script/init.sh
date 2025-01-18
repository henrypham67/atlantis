#!/bin/bash      

# Install CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Create CloudWatch Agent configuration
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "asg-ec2-log-group",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/amazon/ssm/amazon-ssm-agent.log",
            "log_group_name": "asg-ec2-ssm-log-group",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/atlantis/atlantis.log",
            "log_group_name": "atlantis-log-group",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

echo "CloudWatch Agent setup complete"

# install Terraform
yum install -y yum-utils shadow-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform


LATEST_RELEASE=$(curl -s https://api.github.com/repos/runatlantis/atlantis/releases/latest | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4)
curl -LO "$LATEST_RELEASE"
unzip atlantis_linux_amd64.zip
chmod +x atlantis
mv atlantis /usr/local/bin/

# Cloudwatch collect logs
sudo mkdir -p /var/log/atlantis
sudo chmod 755 /var/log/atlantis

export ATLANTIS_REPO_ALLOWLIST=$(aws ssm get-parameter --name "ATLANTIS_REPO_ALLOWLIST" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_USER=$(aws ssm get-parameter --name "ATLANTIS_GH_USER" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_TOKEN=$(aws ssm get-parameter --name "ATLANTIS_GH_TOKEN" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_WEBHOOK_SECRET=$(aws ssm get-parameter --name "ATLANTIS_GH_WEBHOOK_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1)

atlantis server --port 8080 > /var/log/atlantis/atlantis.log 2>&1 &