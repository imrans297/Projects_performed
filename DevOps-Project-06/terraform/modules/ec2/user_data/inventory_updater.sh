#!/bin/bash
# Dynamic Inventory Updater Script
# This script can be run anytime to update the Ansible inventory with current AWS instances

# Configure AWS CLI
export AWS_DEFAULT_REGION=us-east-1

# Function to update inventory
update_inventory() {
    echo "Updating Ansible inventory..."
    
    # Get Jenkins Master IP
    JENKINS_MASTER_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Type,Values=Jenkins Master" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
    
    # Get all Jenkins Agent IPs
    JENKINS_AGENT_IPS=$(aws ec2 describe-instances \
        --filters "Name=tag:Type,Values=Jenkins Agent" "Name=instance-state-name,Values=running" \
        --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
    
    # Create inventory
    sudo tee /etc/ansible/hosts << EOF
[jenkins_master]
jenkins-master ansible_host=$JENKINS_MASTER_IP ansible_user=ubuntu

[jenkins_agents]
EOF
    
    # Add all Jenkins agents dynamically
    count=1
    for ip in $JENKINS_AGENT_IPS; do
        echo "jenkins-agent-$count ansible_host=$ip ansible_user=ubuntu" | sudo tee -a /etc/ansible/hosts
        ((count++))
    done
    
    # Add common variables
    sudo tee -a /etc/ansible/hosts << EOF

[all:vars]
ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible_key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
    
    echo "Inventory updated successfully!"
    echo "Jenkins Master: $JENKINS_MASTER_IP"
    echo "Jenkins Agents: $JENKINS_AGENT_IPS"
    echo "Total Agents: $((count-1))"
}

# Function to test connectivity
test_connectivity() {
    echo "Testing connectivity to all hosts..."
    ansible all -m ping
}

# Function to run playbooks on new agents
setup_new_agents() {
    echo "Setting up any new Jenkins agents..."
    if [ -f /home/ubuntu/playbooks/jenkins-agents.yml ]; then
        ansible-playbook /home/ubuntu/playbooks/jenkins-agents.yml
    fi
}

# Main execution
case "${1:-update}" in
    "update")
        update_inventory
        ;;
    "test")
        test_connectivity
        ;;
    "setup")
        setup_new_agents
        ;;
    "full")
        update_inventory
        test_connectivity
        setup_new_agents
        ;;
    *)
        echo "Usage: $0 {update|test|setup|full}"
        echo "  update - Update inventory from AWS"
        echo "  test   - Test connectivity to all hosts"
        echo "  setup  - Run setup playbooks on agents"
        echo "  full   - Do all of the above"
        exit 1
        ;;
esac