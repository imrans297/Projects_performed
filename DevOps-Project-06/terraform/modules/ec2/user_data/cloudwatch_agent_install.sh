#!/bin/bash

# CloudWatch Agent Installation Script
set -e

# Download and install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

# Create CloudWatch Agent user
useradd -r -s /bin/false cwagent || true

# Create directories
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
mkdir -p /var/log/amazon-cloudwatch-agent

# Set permissions
chown -R cwagent:cwagent /opt/aws/amazon-cloudwatch-agent
chown -R cwagent:cwagent /var/log/amazon-cloudwatch-agent

# Function to start CloudWatch Agent with config from SSM
start_cloudwatch_agent() {
    local config_name="$1"
    
    # Wait for SSM parameter to be available
    for i in {1..30}; do
        if aws ssm get-parameter --name "$config_name" --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region) >/dev/null 2>&1; then
            break
        fi
        echo "Waiting for SSM parameter $config_name to be available... ($i/30)"
        sleep 10
    done
    
    # Start CloudWatch Agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c ssm:$config_name
}

# Export function for use in other scripts
export -f start_cloudwatch_agent

echo "CloudWatch Agent installation completed"