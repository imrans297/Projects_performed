#!/bin/bash
# Minimal Ansible Controller Setup

# Update system
apt-get update -y

# Set hostname
hostnamectl set-hostname ${hostname}

# Install essential packages
apt-get install -y curl wget git python3 python3-pip awscli

# Install Ansible
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Install Python packages for AWS
pip3 install boto3 botocore ansible-core

# Configure AWS CLI with proper credentials
export AWS_DEFAULT_REGION=us-east-1
aws configure set region us-east-1
aws configure set output text

# Create SSH key from Terraform
mkdir -p /home/ubuntu/.ssh
cat > /home/ubuntu/.ssh/ansible_key.pem << 'EOF'
${ansible_private_key}
EOF
chmod 600 /home/ubuntu/.ssh/ansible_key.pem
chown ubuntu:ubuntu /home/ubuntu/.ssh/ansible_key.pem

# Create basic Ansible config
mkdir -p /etc/ansible
cat > /etc/ansible/ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
inventory = /etc/ansible/hosts
remote_user = ubuntu
private_key_file = /home/ubuntu/.ssh/ansible_key.pem
EOF

# Wait for other instances to be ready
sleep 60

# Use Terraform-provided IP addresses
JENKINS_MASTER_IP="${jenkins_master_ip}"
JENKINS_AGENT_IPS='${jenkins_agent_ips}'
JENKINS_AGENT_COUNT=${jenkins_agent_count}

# Parse JSON array of agent IPs
AGENT_IPS_ARRAY=$(echo $JENKINS_AGENT_IPS | python3 -c "import sys, json; print(' '.join(json.load(sys.stdin)))")

# Create Ansible inventory
cat > /etc/ansible/hosts << EOF
[jenkins_master]
jenkins-master ansible_host=$JENKINS_MASTER_IP ansible_user=ubuntu

[jenkins_agents]
EOF

# Add Jenkins agents dynamically
count=1
for ip in $AGENT_IPS_ARRAY; do
  echo "jenkins-agent-$count ansible_host=$ip ansible_user=ubuntu" >> /etc/ansible/hosts
  ((count++))
done

# Add common variables
cat >> /etc/ansible/hosts << EOF

[all:vars]
ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible_key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Create Jenkins playbooks
mkdir -p /home/ubuntu/playbooks

# Jenkins Master playbook
cat > /home/ubuntu/playbooks/jenkins-master.yml << 'PLAYBOOK'
---
- hosts: jenkins_master
  become: yes
  tasks:
    - name: Update apt cache
      apt: update_cache=yes
    - name: Install Java 17
      apt: name=openjdk-17-jdk state=present
    - name: Set JAVA_HOME
      lineinfile:
        path: /etc/environment
        line: 'JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64'
    - name: Add Jenkins key
      apt_key: url=https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key state=present
    - name: Add Jenkins repo
      apt_repository: repo='deb https://pkg.jenkins.io/debian-stable binary/' state=present
    - name: Install Jenkins
      apt: name=jenkins state=present update_cache=yes
    - name: Remove old Jenkins if exists
      apt: name=jenkins state=absent
    - name: Clean Jenkins directory
      file: path=/var/lib/jenkins state=absent
    - name: Reinstall Jenkins
      apt: name=jenkins state=present update_cache=yes
    - name: Fix Jenkins permissions
      file:
        path: /var/lib/jenkins
        owner: jenkins
        group: jenkins
        recurse: yes
    - name: Start and enable Jenkins
      systemd:
        name: jenkins
        state: started
        enabled: yes
        daemon_reload: yes
    - name: Wait for Jenkins
      wait_for: port=8080 delay=30 timeout=300
    - name: Install Docker
      apt: name=docker.io state=present
    - name: Add users to docker group
      user:
        name: "{{ item }}"
        groups: docker
        append: yes
      loop:
        - ubuntu
        - jenkins
    - name: Start Docker
      systemd: name=docker state=started enabled=yes
    - name: Install additional tools
      apt:
        name:
          - curl
          - git
          - wget
          - maven
        state: present
PLAYBOOK

# Jenkins Agents playbook
cat > /home/ubuntu/playbooks/jenkins-agents.yml << 'PLAYBOOK'
---
- hosts: jenkins_agents
  become: yes
  tasks:
    - name: Install Java 17
      apt: name=openjdk-17-jdk state=present update_cache=yes
    - name: Install Docker
      apt: name=docker.io state=present
    - name: Add ubuntu user to docker group
      user: name=ubuntu groups=docker append=yes
    - name: Install build tools
      apt:
        name:
          - maven
          - git
          - curl
          - wget
        state: present
PLAYBOOK

# Combined playbook
cat > /home/ubuntu/playbooks/jenkins-all.yml << 'PLAYBOOK'
---
- import_playbook: jenkins-master.yml
- import_playbook: jenkins-agents.yml
PLAYBOOK

chown -R ubuntu:ubuntu /home/ubuntu/

# Log setup completion
echo "$(date): Ansible Controller setup completed" >> /var/log/user-data.log
echo "Jenkins Master IP: $JENKINS_MASTER_IP" >> /var/log/user-data.log
echo "Jenkins Agent IPs: $AGENT_IPS_ARRAY" >> /var/log/user-data.log
echo "Jenkins Agent Count: $JENKINS_AGENT_COUNT" >> /var/log/user-data.log
echo "Inventory created successfully" >> /var/log/user-data.log