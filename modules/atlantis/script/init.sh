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

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Docker and Docker Compose setup complete"

# Create Docker Compose file
mkdir -p /opt/atlantis
cat <<EOF > /opt/atlantis/docker-compose.yml
version: '3.7'

services:
  atlantis:
    image: ghcr.io/runatlantis/atlantis:latest
    container_name: atlantis-server
    networks:
      - atlantis-network
    ports:
      - "4141:4141"
    volumes:
      - "/var/log/atlantis:/var/log/atlantis"
    environment:
      - ATLANTIS_REPO_ALLOWLIST=${ATLANTIS_REPO_ALLOWLIST}
      - ATLANTIS_GH_USER=${ATLANTIS_GH_USER}
      - ATLANTIS_GH_TOKEN=${ATLANTIS_GH_TOKEN}
      - ATLANTIS_GH_WEBHOOK_SECRET=${ATLANTIS_GH_WEBHOOK_SECRET}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"

  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    networks:
      - atlantis-network
    ports:
      - "80:80"
    volumes:
      - "/etc/nginx/conf.d:/etc/nginx/conf.d"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"

networks:
  atlantis-network:
    driver: bridge
EOF

# Create NGINX configuration
mkdir -p /etc/nginx/conf.d
cat <<EOF > /etc/nginx/conf.d/atlantis.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://atlantis:4141;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Start services using Docker Compose
cd /opt/atlantis
/usr/local/bin/docker-compose up -d

echo "Atlantis and NGINX setup complete using Docker Compose"
