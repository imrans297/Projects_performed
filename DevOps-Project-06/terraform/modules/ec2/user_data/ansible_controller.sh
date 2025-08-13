#!/bin/bash

# User Data Script for Ansible Controller
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
    python3 \
    python3-pip \
    python3-venv \
    awscli

# Install Ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Install additional Python packages for Ansible
pip3 install \
    boto3 \
    botocore \
    ansible-core \
    jmespath \
    netaddr

# Configure AWS CLI for dynamic inventory
aws configure set region us-east-1
aws configure set output json

# Configure Ansible
mkdir -p /etc/ansible
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
inventory = /etc/ansible/hosts
remote_user = ubuntu
private_key_file = /home/ubuntu/.ssh/ansible_key.pem
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml
callback_whitelist = timer, profile_tasks

[inventory]
enable_plugins = aws_ec2, host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
EOF

# Create Ansible inventory directory
mkdir -p /etc/ansible/inventories

# Create dynamic inventory for AWS EC2
cat > /etc/ansible/inventories/aws_ec2.yml << 'EOF'
plugin: aws_ec2
regions:
  - us-east-1
keyed_groups:
  - key: tags.Type
    prefix: type
  - key: tags.Role
    prefix: role
  - key: instance_type
    prefix: instance_type
compose:
  ansible_host: public_ip_address | default(private_ip_address)
EOF

# Create script to generate static inventory from AWS
cat > /home/ubuntu/update_inventory.sh << 'EOF'
#!/bin/bash
# Script to update Ansible inventory from AWS

# Get Jenkins Master IP
JENKINS_MASTER_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Type,Values=Jenkins Master" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

# Get Jenkins Agent IPs
JENKINS_AGENT_IPS=$(aws ec2 describe-instances \
  --filters "Name=tag:Type,Values=Jenkins Agent" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

# Create static inventory
sudo tee /etc/ansible/hosts << INVENTORY_EOF
[jenkins_master]
jenkins-master ansible_host=$JENKINS_MASTER_IP ansible_user=ubuntu

[jenkins_agents]
INVENTORY_EOF

# Add Jenkins agents
count=1
for ip in $JENKINS_AGENT_IPS; do
  echo "jenkins-agent-$count ansible_host=$ip ansible_user=ubuntu" | sudo tee -a /etc/ansible/hosts
  ((count++))
done

# Add common variables
sudo tee -a /etc/ansible/hosts << INVENTORY_EOF

[all:vars]
ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible_key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY_EOF

echo "Inventory updated successfully"
EOF

chmod +x /home/ubuntu/update_inventory.sh
chown ubuntu:ubuntu /home/ubuntu/update_inventory.sh

# Create Ansible playbooks directory
mkdir -p /home/ubuntu/ansible-playbooks
chown -R ubuntu:ubuntu /home/ubuntu/ansible-playbooks

# Create Jenkins installation playbook
cat > /home/ubuntu/ansible-playbooks/jenkins-installation.yml << 'EOF'
---
- name: Install Jenkins Master
  hosts: type_Jenkins_Master
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        
    - name: Install Java 11
      apt:
        name: openjdk-11-jdk
        state: present
        
    - name: Add Jenkins repository key
      apt_key:
        url: https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
        state: present
        
    - name: Add Jenkins repository
      apt_repository:
        repo: deb https://pkg.jenkins.io/debian-stable binary/
        state: present
        
    - name: Install Jenkins
      apt:
        name: jenkins
        state: present
        update_cache: yes
        
    - name: Start and enable Jenkins
      systemd:
        name: jenkins
        state: started
        enabled: yes
        
    - name: Wait for Jenkins to start
      wait_for:
        port: 8080
        delay: 30
        timeout: 300
        
    - name: Install Docker
      apt:
        name: docker.io
        state: present
        
    - name: Add ubuntu and jenkins users to docker group
      user:
        name: "{{ item }}"
        groups: docker
        append: yes
      loop:
        - ubuntu
        - jenkins
        
    - name: Start and enable Docker
      systemd:
        name: docker
        state: started
        enabled: yes
        
    - name: Install additional tools
      apt:
        name:
          - maven
          - git
          - curl
          - wget
        state: present
EOF

# Create Jenkins agent setup playbook
cat > /home/ubuntu/ansible-playbooks/jenkins-agent-setup.yml << 'EOF'
---
- name: Setup Jenkins Agents
  hosts: type_Jenkins_Agent
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        
    - name: Install Java 11
      apt:
        name: openjdk-11-jdk
        state: present
        
    - name: Install Docker
      apt:
        name: docker.io
        state: present
        
    - name: Add ubuntu user to docker group
      user:
        name: ubuntu
        groups: docker
        append: yes
        
    - name: Start and enable Docker
      systemd:
        name: docker
        state: started
        enabled: yes
        
    - name: Install build tools
      apt:
        name:
          - maven
          - gradle
          - git
          - curl
          - wget
          - python3
          - python3-pip
        state: present
        
    - name: Install Node.js
      shell: |
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        apt-get install -y nodejs
      args:
        creates: /usr/bin/node
EOF

chown -R ubuntu:ubuntu /home/ubuntu/ansible-playbooks/

# Install Docker for Ansible
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

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

# Create SSH key for Ansible from Terraform
mkdir -p /home/ubuntu/.ssh
cat > /home/ubuntu/.ssh/ansible_key.pem << 'SSH_KEY_EOF'
${ansible_private_key}
SSH_KEY_EOF

cat > /home/ubuntu/.ssh/ansible_key.pub << 'SSH_PUB_EOF'
${ansible_public_key}
SSH_PUB_EOF

chmod 600 /home/ubuntu/.ssh/ansible_key.pem
chmod 644 /home/ubuntu/.ssh/ansible_key.pub
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Wait for other instances to be ready and update inventory
sleep 60
sudo -u ubuntu /home/ubuntu/update_inventory.sh

# Create welcome message
cat > /etc/motd << 'EOF'
*****************************************************
*                                                   *
*           Ansible Controller Server               *
*                                                   *
*  This server is configured for CI/CD pipeline    *
*  management and infrastructure automation.       *
*                                                   *
*  Ansible is installed and ready to use.          *
*  Check /home/ubuntu/ansible-playbooks/ for       *
*  sample playbooks.                                *
*                                                   *
*****************************************************
EOF

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

# Log completion
echo "$(date): Ansible Controller setup completed" >> /var/log/user-data.log

# Reboot to ensure all changes take effect
reboot