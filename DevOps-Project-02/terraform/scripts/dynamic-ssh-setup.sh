#!/bin/bash

# Dynamic SSH Key Setup for ASG instances
set -e

BASTION_IP="$1"
ORIGINAL_KEY="$2"
BASTION_KEY_PATH="$3"
ASG_NAME="$4"

echo "Dynamic SSH key setup for ASG: $ASG_NAME"

# Generate SSH key if not exists
if [ ! -f "$BASTION_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$BASTION_KEY_PATH" -N "" -C "bastion-to-private"
fi

# Copy private key to bastion
scp -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no \
    "$BASTION_KEY_PATH" ubuntu@"$BASTION_IP":~/.ssh/bastion_key

ssh -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no ubuntu@"$BASTION_IP" \
    "chmod 600 ~/.ssh/bastion_key"

# Get current running instances
PRIVATE_IPS=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)

# Add key to each instance
for IP in $PRIVATE_IPS; do
    echo "Adding SSH key to $IP..."
    ssh -i "$ORIGINAL_KEY" -o StrictHostKeyChecking=no \
        -J ubuntu@"$BASTION_IP" ubuntu@"$IP" \
        "echo '$(cat ${BASTION_KEY_PATH}.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" || echo "Failed to add key to $IP"
done

echo "SSH setup completed for current instances"