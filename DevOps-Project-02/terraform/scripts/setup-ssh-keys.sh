#!/bin/bash

# SSH Key Setup Script
set -e

BASTION_IP="$1"
PRIVATE_IPS="$2"
ORIGINAL_KEY="$3"
BASTION_KEY_PATH="$4"

echo "Setting up SSH keys..."
echo "Bastion IP: $BASTION_IP"
echo "Private IPs: $PRIVATE_IPS"

# Generate SSH key pair if not exists
if [ ! -f "$BASTION_KEY_PATH" ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t ed25519 -f "$BASTION_KEY_PATH" -N "" -C "bastion-to-private"
fi

# Copy private key to bastion host
echo "Copying private key to bastion..."
scp -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no \
    "$BASTION_KEY_PATH" ubuntu@"$BASTION_IP":~/.ssh/bastion_key

# Set correct permissions on bastion
ssh -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no ubuntu@"$BASTION_IP" \
    "chmod 600 ~/.ssh/bastion_key"

# Add public key to each private instance
for PRIVATE_IP in $PRIVATE_IPS; do
    echo "Adding public key to $PRIVATE_IP..."
    
    # Copy public key to private instance via bastion
    ssh -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no \
        -J ubuntu@"$BASTION_IP" ubuntu@"$PRIVATE_IP" \
        "echo '$(cat ${BASTION_KEY_PATH}.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done

echo "SSH key setup completed!"
echo "You can now SSH from bastion to private instances using: ssh -i ~/.ssh/bastion_key ubuntu@PRIVATE_IP"