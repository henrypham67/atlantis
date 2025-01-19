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
            "file_path": "/var/lib/docker/containers/*/*.log",
            "log_group_name": "docker-containers-log-group",
            "log_stream_name": "docker-{container_id}",
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

# Install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Terraform
yum install -y yum-utils shadow-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform

# Download and set up Atlantis
LATEST_RELEASE=$(curl -s https://api.github.com/repos/runatlantis/atlantis/releases/latest | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4)
curl -LO "$LATEST_RELEASE"
unzip atlantis_linux_amd64.zip
chmod +x atlantis
mv atlantis /usr/local/bin/

# CloudWatch log setup
sudo mkdir -p /var/log/atlantis
sudo chmod 755 /var/log/atlantis

# Fetch parameters from AWS SSM Parameter Store
export ATLANTIS_REPO_ALLOWLIST=$(aws ssm get-parameter --name "ATLANTIS_REPO_ALLOWLIST" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_USER=$(aws ssm get-parameter --name "ATLANTIS_GH_USER" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_TOKEN=$(aws ssm get-parameter --name "ATLANTIS_GH_TOKEN" --with-decryption --query "Parameter.Value" --output text --region us-east-1)
export ATLANTIS_GH_WEBHOOK_SECRET=$(aws ssm get-parameter --name "ATLANTIS_GH_WEBHOOK_SECRET" --with-decryption --query "Parameter.Value" --output text --region us-east-1)

docker network create atlantis-network

# Run Atlantis Docker container
docker run --name atlantis-server -d \
  -p 4141:4141 \
  -v /var/log/atlantis:/var/log/atlantis \
  -e ATLANTIS_REPO_ALLOWLIST="$ATLANTIS_REPO_ALLOWLIST" \
  -e ATLANTIS_GH_USER="$ATLANTIS_GH_USER" \
  -e ATLANTIS_GH_TOKEN="$ATLANTIS_GH_TOKEN" \
  -e ATLANTIS_GH_WEBHOOK_SECRET="$ATLANTIS_GH_WEBHOOK_SECRET" \
  --log-driver json-file \
  --log-opt max-size=10m \
  --network atlantis-network \
  ghcr.io/runatlantis/atlantis:latest

# Create NGINX configuration for Atlantis in Docker
mkdir -p /etc/nginx/conf.d
cat <<EOF > /etc/nginx/conf.d/atlantis.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://atlantis-server:4141;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Run NGINX in Docker
docker run --name nginx-proxy -d \
  -p 80:80 \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --network atlantis-network \
  nginx:latest

# Reload NGINX container to apply the configuration
docker exec nginx-proxy nginx -s reload
