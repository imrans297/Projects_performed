#!/bin/bash

# User Data Script for Jenkins Master
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Set hostname
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    awscli

# Install Java 11 (required for Jenkins)
apt-get install -y openjdk-11-jdk

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment
source /etc/environment

# Add Jenkins repository key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | apt-key add -

# Add Jenkins repository
echo "deb https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list

# Update package list and install Jenkins
apt-get update -y
apt-get install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Add jenkins user to docker group
usermod -aG docker jenkins
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# Install Maven
apt-get install -y maven

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Configure Jenkins
mkdir -p /var/lib/jenkins/init.groovy.d

# Create Jenkins initial configuration script
cat > /var/lib/jenkins/init.groovy.d/basic-security.groovy << 'EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Disable CLI over remoting
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Enable Agent to Master Access Control
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

instance.save()
EOF

# Create Jenkins plugin installation script
cat > /var/lib/jenkins/init.groovy.d/install-plugins.groovy << 'EOF'
#!groovy

import jenkins.model.Jenkins
import java.util.logging.Logger

def logger = Logger.getLogger("")
def installed = false
def initialized = false

def pluginParameter = "ant build-timeout credentials-binding timestamper ws-cleanup github-branch-source pipeline-github-lib pipeline-stage-view git ssh-slaves matrix-auth pam-auth ldap email-ext mailer docker-workflow docker-pipeline kubernetes kubernetes-cli aws-credentials ec2 s3 pipeline-aws sonar quality-gates-plugin artifactory blueocean"

def plugins = pluginParameter.split()
logger.info("" + plugins)
def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()
uc.updateAllSites()

plugins.each {
  logger.info("Checking " + it)
  if (!pm.getPlugin(it)) {
    logger.info("Looking UpdateCenter for " + it)
    if (!initialized) {
      uc.updateAllSites()
      initialized = true
    }
    def plugin = uc.getPlugin(it)
    if (plugin) {
      logger.info("Installing " + it)
      plugin.deploy()
      installed = true
    }
  }
}

if (installed) {
  logger.info("Plugins installed, initializing a restart!")
  instance.save()
  instance.restart()
}
EOF

# Set ownership for Jenkins files
chown -R jenkins:jenkins /var/lib/jenkins/

# Configure Jenkins service to wait for network
mkdir -p /etc/systemd/system/jenkins.service.d
cat > /etc/systemd/system/jenkins.service.d/override.conf << 'EOF'
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx2048m -XX:MaxPermSize=512m -XX:+UseConcMarkSweepGC"
EOF

# Reload systemd and restart Jenkins
systemctl daemon-reload
systemctl restart jenkins

# Wait for Jenkins to start
sleep 60

# Create Jenkins jobs directory
mkdir -p /var/lib/jenkins/jobs
chown jenkins:jenkins /var/lib/jenkins/jobs

# Configure firewall (if ufw is enabled)
if systemctl is-active --quiet ufw; then
    ufw allow 8080/tcp
    ufw allow 50000/tcp
fi

# Create welcome message
cat > /etc/motd << 'EOF'
*****************************************************
*                                                   *
*              Jenkins Master Server                *
*                                                   *
*  Jenkins is running on port 8080                 *
*  Default admin credentials: admin/admin123       *
*                                                   *
*  Please change the default password after        *
*  first login for security.                       *
*                                                   *
*  Access Jenkins at: http://YOUR_IP:8080          *
*                                                   *
*****************************************************
EOF

# Create Jenkins status check script
cat > /home/ubuntu/check-jenkins.sh << 'EOF'
#!/bin/bash
echo "Jenkins Status:"
systemctl status jenkins --no-pager -l

echo -e "\nJenkins Logs (last 20 lines):"
tail -20 /var/log/jenkins/jenkins.log

echo -e "\nJenkins URL:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

echo -e "\nInitial Admin Password:"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Password file not found. Jenkins may still be starting."
fi
EOF

chmod +x /home/ubuntu/check-jenkins.sh
chown ubuntu:ubuntu /home/ubuntu/check-jenkins.sh

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent to send Jenkins logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/jenkins/jenkins.log",
                        "log_group_name": "/aws/ec2/jenkins-master",
                        "log_stream_name": "{instance_id}/jenkins.log",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ec2/jenkins-master",
                        "log_stream_name": "{instance_id}/syslog",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Log completion
echo "$(date): Jenkins Master setup completed" >> /var/log/user-data.log

# Final restart to ensure all services are properly configured
systemctl restart jenkins docker