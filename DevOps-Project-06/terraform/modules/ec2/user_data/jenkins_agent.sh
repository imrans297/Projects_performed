#!/bin/bash

# User Data Script for Jenkins Agent
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
    awscli \
    build-essential

# Install Java 11 (required for Jenkins agent)
apt-get install -y openjdk-11-jdk

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /etc/environment
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/environment
source /etc/environment

# Install Docker
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Maven
apt-get install -y maven

# Install Gradle
wget https://services.gradle.org/distributions/gradle-7.6-bin.zip -P /tmp
unzip -d /opt/gradle /tmp/gradle-*.zip
echo 'export GRADLE_HOME=/opt/gradle/gradle-7.6' >> /etc/environment
echo 'export PATH=$PATH:$GRADLE_HOME/bin' >> /etc/environment

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Python and pip
apt-get install -y python3 python3-pip python3-venv

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Install SonarQube Scanner
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
unzip sonar-scanner-cli-4.8.0.2856-linux.zip -d /opt/
mv /opt/sonar-scanner-4.8.0.2856-linux /opt/sonar-scanner
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' >> /etc/environment

# Install Trivy (security scanner)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

# Install OWASP Dependency Check
wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip -d /opt/
mv /opt/dependency-check /opt/dependency-check
echo 'export PATH=$PATH:/opt/dependency-check/bin' >> /etc/environment

# Create Jenkins agent user
useradd -m -s /bin/bash jenkins
usermod -aG docker jenkins
usermod -aG sudo jenkins

# Create Jenkins agent directory
mkdir -p /home/jenkins/agent
chown jenkins:jenkins /home/jenkins/agent

# Setup SSH for Jenkins agent
mkdir -p /home/jenkins/.ssh
chown jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh

# Create Jenkins agent service (will be configured by Ansible later)
cat > /etc/systemd/system/jenkins-agent.service << 'EOF'
[Unit]
Description=Jenkins Agent
After=network.target

[Service]
Type=simple
User=jenkins
WorkingDirectory=/home/jenkins/agent
ExecStart=/usr/bin/java -jar /home/jenkins/agent/agent.jar -jnlpUrl http://${jenkins_master_ip}:8080/computer/${hostname}/slave-agent.jnlp -secret @/home/jenkins/agent/secret-file -workDir /home/jenkins/agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Mount additional EBS volume for Docker and build artifacts
mkdir -p /var/lib/docker-data
if [ -b /dev/xvdf ]; then
    mkfs.ext4 /dev/xvdf
    echo '/dev/xvdf /var/lib/docker-data ext4 defaults,nofail 0 2' >> /etc/fstab
    mount -a
    chown ubuntu:ubuntu /var/lib/docker-data
fi

# Configure Docker to use additional storage
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
    "data-root": "/var/lib/docker-data",
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

# Restart Docker with new configuration
systemctl restart docker

# Install additional development tools
apt-get install -y \
    jq \
    yq \
    zip \
    unzip \
    rsync \
    openssh-client \
    ca-certificates \
    gnupg2 \
    software-properties-common

# Create build workspace
mkdir -p /home/ubuntu/workspace
chown ubuntu:ubuntu /home/ubuntu/workspace

# Create welcome message
cat > /etc/motd << 'EOF'
*****************************************************
*                                                   *
*              Jenkins Agent Server                 *
*                                                   *
*  This server is configured as a Jenkins build    *
*  agent with the following tools installed:       *
*                                                   *
*  - Java 11                                        *
*  - Docker & Docker Compose                       *
*  - Maven & Gradle                                 *
*  - Node.js & npm                                  *
*  - Python 3 & pip                                *
*  - AWS CLI v2                                     *
*  - kubectl & Helm                                 *
*  - Terraform                                      *
*  - SonarQube Scanner                              *
*  - Trivy Security Scanner                         *
*  - OWASP Dependency Check                         *
*                                                   *
*  Agent Number: ${agent_number}                    *
*  Jenkins Master IP: ${jenkins_master_ip}          *
*                                                   *
*****************************************************
EOF

# Create agent info script
cat > /home/ubuntu/agent-info.sh << 'EOF'
#!/bin/bash
echo "Jenkins Agent Information:"
echo "=========================="
echo "Agent Number: ${agent_number}"
echo "Jenkins Master IP: ${jenkins_master_ip}"
echo "Hostname: ${hostname}"
echo ""
echo "Installed Tools:"
echo "- Java: $(java -version 2>&1 | head -n 1)"
echo "- Docker: $(docker --version)"
echo "- Maven: $(mvn --version | head -n 1)"
echo "- Node.js: $(node --version)"
echo "- Python: $(python3 --version)"
echo "- AWS CLI: $(aws --version)"
echo "- kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl installed')"
echo "- Helm: $(helm version --short 2>/dev/null || echo 'helm installed')"
echo "- Terraform: $(terraform --version | head -n 1)"
echo ""
echo "Docker Status:"
systemctl status docker --no-pager -l | head -n 5
EOF

chmod +x /home/ubuntu/agent-info.sh
chown ubuntu:ubuntu /home/ubuntu/agent-info.sh

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent for Jenkins Agent
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
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ec2/jenkins-agents",
                        "log_stream_name": "{instance_id}/syslog",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/home/jenkins/agent/agent.log",
                        "log_group_name": "/aws/ec2/jenkins-agents",
                        "log_stream_name": "{instance_id}/agent.log",
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
echo "$(date): Jenkins Agent ${agent_number} setup completed" >> /var/log/user-data.log

# Final system update and cleanup
apt-get autoremove -y
apt-get autoclean