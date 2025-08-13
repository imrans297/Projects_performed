#!/bin/bash
# Minimal Jenkins Master Setup - Jenkins will be installed via Ansible

# Update system
apt-get update -y

# Set hostname
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install basic packages
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    python3 \
    python3-pip

# Add Ansible SSH key to authorized_keys
mkdir -p /home/ubuntu/.ssh
echo "${ansible_public_key}" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Signal completion
echo "Jenkins Master minimal setup completed" > /tmp/setup_complete