# Complete CI/CD Infrastructure Setup Guide

## 🏗️ Overview

This guide provides a comprehensive walkthrough of the automated CI/CD infrastructure deployment using Terraform and Ansible. The setup creates a fully functional Jenkins-based CI/CD pipeline with dynamic inventory management and automated configuration.

---

## 📋 Architecture Components

### **Infrastructure Stack:**
- **Terraform**: Infrastructure as Code (IaC) for AWS resource provisioning
- **Ansible**: Configuration management and application deployment
- **Jenkins**: CI/CD orchestration platform
- **AWS**: Cloud infrastructure provider

### **Key Features:**
- ✅ **Fully Automated**: Zero manual configuration required
- ✅ **Dynamic Scaling**: Automatically handles new Jenkins agents
- ✅ **Secure**: Terraform-generated SSH keys and IAM roles
- ✅ **Monitoring**: CloudWatch dashboards and alerts
- ✅ **High Availability**: Multi-AZ deployment

---

## 🚀 Quick Start

### **Prerequisites:**
```bash
# Required tools
- Terraform >= 1.0
- AWS CLI configured
- SSH key pair in /home/imranshaikh/MY_keys/mydev_key.pem
```

### **Deploy Infrastructure:**
```bash
cd /home/imranshaikh/Practices/my_prjects/DevOps-Project-06/terraform

# Initialize Terraform
terraform init

# Deploy infrastructure
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

### **Access Points:**
- **Jenkins UI**: `http://<jenkins_master_ip>:8080`
- **Ansible Controller**: `ssh -i /home/imranshaikh/MY_keys/mydev_key.pem ubuntu@<ansible_controller_ip>`
- **Monitoring Dashboard**: Available in Terraform outputs

---

## 🔧 Detailed Component Breakdown

### **1. VPC Module (`modules/vpc/`)**

**Purpose**: Creates the network foundation for the entire infrastructure.

**Resources Created:**
- 1 VPC (10.0.0.0/16) with DNS support
- 2 Public Subnets across 2 AZs
- 2 Private Subnets across 2 AZs
- Internet Gateway + 2 NAT Gateways
- Route tables and associations
- VPC Flow Logs with CloudWatch integration

**Key Features:**
- High availability across multiple AZs
- Secure private subnets for Jenkins agents
- Internet access for all instances

### **2. Security Groups Module (`modules/security-groups/`)**

**Purpose**: Implements network-level security controls.

**Security Groups Created:**
- **Common SG**: SSH (22) + internal VPC communication
- **Ansible Controller SG**: HTTP/HTTPS + Ansible ports (5986)
- **Jenkins Master SG**: Jenkins UI (8080) + Agent communication (50000)
- **Jenkins Agent SG**: Docker (2376) + SonarQube (9000)
- **EKS Additional SG**: Kubernetes API + NodePort range
- **ALB SG**: Load balancer traffic
- **Database SG**: MySQL/PostgreSQL ports

**Security Principles:**
- Least privilege access
- Port-specific rules
- VPC-internal communication only where needed

### **3. IAM Module (`modules/iam/`)**

**Purpose**: Manages AWS permissions and access control.

**Roles Created:**
- **Ansible Controller Role**: EC2 + SSM + S3 permissions
- **Jenkins Master Role**: EC2 + EKS + ECR + S3 permissions
- **Jenkins Agent Role**: ECR + EKS + S3 for builds/deployments
- **EKS Cluster Role**: EKS cluster management
- **EKS Node Group Role**: Worker node permissions

**Key Capabilities:**
- Secure AWS API access for all instances
- Jenkins deployment to EKS clusters
- Docker image push/pull from ECR
- S3 access for artifacts and logs

### **4. S3 Module (`modules/s3/`)**

**Purpose**: Provides storage for artifacts, logs, and Terraform state.

**Buckets Created:**
- **Artifacts Bucket**: Build artifacts and Docker metadata
- **Terraform State Bucket**: Remote state storage
- **Logs Bucket**: Application and system logs

**Features:**
- Versioning enabled on all buckets
- AES256 encryption at rest
- Lifecycle policies for cost optimization
- Public access blocked by default
- DynamoDB table for state locking

### **5. EC2 Module (`modules/ec2/`) - The Heart of the Setup**

**Purpose**: Creates and configures all compute instances with automated setup.

#### **🔑 SSH Key Management (Automated)**
```hcl
# Terraform generates SSH keys automatically
resource "tls_private_key" "ansible_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Creates AWS key pair from generated public key
resource "aws_key_pair" "ansible_ssh" {
  key_name   = "${var.ansible_controller_config.name}-ansible-key"
  public_key = tls_private_key.ansible_ssh.public_key_openssh
}

# Stores private key securely in AWS SSM
resource "aws_ssm_parameter" "ansible_private_key" {
  name  = "/${var.ansible_controller_config.name}/ssh/private-key"
  type  = "SecureString"
  value = tls_private_key.ansible_ssh.private_key_pem
}
```

#### **🖥️ Instance Configurations**

**Ansible Controller:**
- **Instance Type**: t2.micro (configurable)
- **Location**: Public subnet (internet accessible)
- **Purpose**: Configuration management hub
- **Key Features**:
  - Terraform-generated SSH keys embedded
  - Dynamic inventory management
  - Automated playbook execution
  - Cron job for inventory updates every 5 minutes

**Jenkins Master:**
- **Instance Type**: t2.medium (configurable)
- **Location**: Public subnet (web UI accessible)
- **Purpose**: CI/CD orchestration
- **Key Features**:
  - Minimal setup (Jenkins installed via Ansible)
  - Java 17 compatibility
  - Docker integration
  - Elastic IP for consistent access

**Jenkins Agents:**
- **Instance Type**: t2.medium (configurable)
- **Location**: Private subnets (secure build environment)
- **Purpose**: Build execution
- **Key Features**:
  - Scalable (count configurable)
  - Additional 50GB EBS volume for Docker
  - Build tools installed via Ansible

#### **🔄 Dynamic Inventory System**

**How it Works:**
1. **Terraform generates** SSH keys and passes them to instances
2. **User data scripts** embed keys and create inventory updater
3. **Cron job** runs every 5 minutes to discover new instances
4. **Ansible playbooks** automatically configure new agents

**Dynamic Inventory Script (`inventory_updater.sh`):**
```bash
# Automatically discovers all Jenkins instances by AWS tags
JENKINS_MASTER_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Type,Values=Jenkins Master" \
    --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

JENKINS_AGENT_IPS=$(aws ec2 describe-instances \
    --filters "Name=tag:Type,Values=Jenkins Agent" \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)

# Creates inventory dynamically
# Supports unlimited number of agents
# Runs automatically via cron job
```

### **6. Monitoring Module (`modules/monitoring/`)**

**Purpose**: Comprehensive monitoring and alerting system.

**Monitoring Coverage:**
- System metrics (CPU, Memory, Disk)
- Jenkins-specific metrics
- Instance health checks
- Log analysis and error detection
- Email alerts via SNS

---

## 🔧 Automated Setup Process

### **Phase 1: Infrastructure Provisioning (Terraform)**
```bash
terraform apply -var-file="environments/dev.tfvars"
```

**What Happens:**
1. **Network Setup**: VPC, subnets, gateways, security groups
2. **IAM Configuration**: Roles and policies for secure access
3. **Storage Setup**: S3 buckets with encryption and lifecycle policies
4. **Key Generation**: Terraform creates SSH key pairs automatically
5. **Instance Creation**: Minimal instances with embedded SSH keys

### **Phase 2: Configuration Management (Ansible)**

**Automated via Terraform Provisioner:**
1. **SSH Key Distribution**: Terraform-generated keys embedded in user data
2. **Inventory Creation**: Dynamic discovery of all instances
3. **Connectivity Testing**: Automated ping tests
4. **Application Installation**: Jenkins and tools via Ansible playbooks

### **Phase 3: Dynamic Management**

**Ongoing Automation:**
- **Cron Job**: Updates inventory every 5 minutes
- **Auto-Discovery**: New agents automatically added to inventory
- **Auto-Configuration**: New agents automatically configured

---

## 📝 Key Scripts and Playbooks

### **User Data Scripts:**

#### **Ansible Controller (`ansible_controller_simple.sh`):**
```bash
# Key Features:
- Installs Ansible and Python packages
- Embeds Terraform-generated SSH keys
- Creates dynamic inventory updater script
- Sets up cron job for automatic updates
- Creates Jenkins installation playbooks
- Configures AWS CLI for dynamic discovery
```

#### **Jenkins Master (`jenkins_master_minimal.sh`):**
```bash
# Minimal setup approach:
- Basic system packages only
- SSH key configuration
- Jenkins installed via Ansible (not user data)
- Faster boot time
```

#### **Jenkins Agent (`jenkins_agent_minimal.sh`):**
```bash
# Minimal setup approach:
- Basic system packages only
- SSH key configuration
- Additional EBS volume mounting
- Tools installed via Ansible
```

### **Ansible Playbooks:**

#### **Jenkins Master Installation:**
```yaml
# /home/ubuntu/playbooks/jenkins-master.yml
- Install Java 17 (Jenkins requirement)
- Configure JAVA_HOME
- Add Jenkins repository and key
- Install and configure Jenkins
- Install Docker and build tools
- Add users to docker group
- Install curl, git, wget, maven
```

#### **Jenkins Agents Setup:**
```yaml
# /home/ubuntu/playbooks/jenkins-agents.yml
- Install Java 17
- Install Docker and build tools
- Configure additional EBS volume
- Install Maven, Git, Curl, Wget
- Configure build environment
```

#### **Dynamic Inventory Management:**
```bash
# /home/ubuntu/inventory_updater.sh
- Discovers all Jenkins instances via AWS tags
- Creates static inventory file
- Supports unlimited number of agents
- Can be run manually or via cron
- Usage: ./inventory_updater.sh {update|test|setup|full}
```

---

## 🔄 Scaling Jenkins Agents

### **Adding New Agents:**

**Method 1: Update Terraform Variable**
```bash
# Edit environments/dev.tfvars
jenkins_agents_count = 3  # Increase from 1 to 3

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

**Method 2: Manual Agent Creation**
```bash
# Create additional agent with proper tags
aws ec2 run-instances \
  --image-id ami-021589336d307b577 \
  --instance-type t2.medium \
  --key-name dev-cicd-pipeline-ansible-controller-ansible-key \
  --subnet-id subnet-0ebede3a26f4d2a92 \
  --security-group-ids sg-00dae5841b5ede5ee sg-0409f7a01d82d8485 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Type,Value=Jenkins Agent},{Key=Role,Value=CI/CD Worker}]'
```

**Automatic Discovery:**
- New agents are automatically discovered within 5 minutes
- Inventory is updated via cron job
- Agents are automatically configured via Ansible

### **Testing New Agents:**
```bash
# Connect to Ansible controller
ssh -i /home/imranshaikh/MY_keys/mydev_key.pem ubuntu@<ansible_controller_ip>

# Update inventory manually (or wait for cron)
/home/ubuntu/inventory_updater.sh update

# Test connectivity to all agents
ansible jenkins_agents -m ping

# Configure new agents
ansible-playbook /home/ubuntu/playbooks/jenkins-agents.yml --limit jenkins_agents
```

---

## 🛠️ Troubleshooting Guide

### **Common Issues and Solutions:**

#### **1. Jenkins Won't Start**
```bash
# Check Java version (must be 17 or 21)
ansible jenkins_master -m shell -a "java -version"

# Fix Java version
ansible-playbook /home/ubuntu/playbooks/jenkins-java17-fix.yml
```

#### **2. Ansible Can't Connect to Instances**
```bash
# Update inventory
/home/ubuntu/inventory_updater.sh update

# Test connectivity
ansible all -m ping

# Check SSH key permissions
ls -la ~/.ssh/ansible_key.pem
```

#### **3. New Agents Not Discovered**
```bash
# Manual inventory update
/home/ubuntu/inventory_updater.sh full

# Check cron job
crontab -l

# Verify AWS tags on new instances
aws ec2 describe-instances --filters "Name=tag:Type,Values=Jenkins Agent"
```

#### **4. Dynamic Inventory Not Working**
```bash
# Test AWS CLI access
aws sts get-caller-identity

# Test dynamic inventory
ansible-inventory -i /etc/ansible/inventories/aws_ec2.yml --list

# Fall back to static inventory
/home/ubuntu/inventory_updater.sh update
```

---

## 📊 Monitoring and Maintenance

### **CloudWatch Monitoring:**
- **Dashboard**: Real-time infrastructure overview
- **Alarms**: CPU, Memory, Disk, Jenkins metrics
- **Logs**: Centralized logging for all components
- **Alerts**: Email notifications via SNS

### **Regular Maintenance Tasks:**

#### **Weekly:**
```bash
# Check system health
ansible all -m shell -a "df -h && free -h"

# Update packages
ansible all -m apt -a "update_cache=yes upgrade=yes" --become
```

#### **Monthly:**
```bash
# Review CloudWatch costs
# Check S3 bucket sizes
# Review security group rules
# Update Jenkins plugins
```

---

## 🔐 Security Best Practices

### **Implemented Security Measures:**

1. **Network Security:**
   - Private subnets for Jenkins agents
   - Security groups with minimal required ports
   - VPC isolation

2. **Access Control:**
   - IAM roles with least privilege
   - Terraform-generated SSH keys
   - No hardcoded credentials

3. **Data Protection:**
   - Encrypted EBS volumes
   - Encrypted S3 buckets
   - Secure parameter storage in SSM

4. **Monitoring:**
   - VPC Flow Logs
   - CloudWatch monitoring
   - Automated alerting

### **Security Recommendations:**

```bash
# Restrict SSH access in production
allowed_ssh_cidr = "YOUR_IP/32"  # Instead of 0.0.0.0/0

# Enable MFA for AWS accounts
# Regular security audits
# Keep Jenkins and plugins updated
```

---

## 📁 File Structure

```
terraform/
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Variable definitions
├── locals.tf                   # Local values and common tags
├── outputs.tf                  # Output values
├── environments/
│   ├── dev.tfvars             # Development environment config
│   └── prod.tfvars            # Production environment config
├── modules/
│   ├── vpc/                   # VPC and networking
│   ├── security-groups/       # Security group definitions
│   ├── iam/                   # IAM roles and policies
│   ├── s3/                    # S3 buckets and policies
│   ├── ec2/                   # EC2 instances and configuration
│   │   ├── main.tf           # EC2 resources and provisioners
│   │   ├── variables.tf      # EC2 module variables
│   │   ├── outputs.tf        # EC2 module outputs
│   │   └── user_data/        # Instance initialization scripts
│   │       ├── ansible_controller_simple.sh
│   │       ├── jenkins_master_minimal.sh
│   │       ├── jenkins_agent_minimal.sh
│   │       ├── inventory_updater.sh
│   │       └── cron_inventory_update.sh
│   ├── monitoring/            # CloudWatch monitoring
│   └── eks/                   # EKS cluster (future use)
└── COMPLETE_SETUP_GUIDE.md    # This guide
```

---

## 🎯 Advanced Configuration

### **Scaling Configuration:**

#### **Horizontal Scaling (More Agents):**
```hcl
# In environments/dev.tfvars
jenkins_agents_count = 5  # Scale to 5 agents
```

#### **Vertical Scaling (Bigger Instances):**
```hcl
# In environments/dev.tfvars
jenkins_master_instance_type = "t3.large"
jenkins_agent_instance_type = "t3.large"
```

#### **Multi-Environment Setup:**
```bash
# Development
terraform apply -var-file="environments/dev.tfvars"

# Production
terraform apply -var-file="environments/prod.tfvars"
```

### **Custom Playbook Integration:**

#### **Adding New Playbooks:**
```bash
# Connect to Ansible controller
ssh -i /home/imranshaikh/MY_keys/mydev_key.pem ubuntu@<ansible_controller_ip>

# Create custom playbook
cat > /home/ubuntu/playbooks/custom-setup.yml << 'EOF'
---
- hosts: jenkins_agents
  become: yes
  tasks:
    - name: Install custom tools
      apt:
        name:
          - nodejs
          - python3-pip
          - kubectl
        state: present
EOF

# Run custom playbook
ansible-playbook /home/ubuntu/playbooks/custom-setup.yml
```

---

## 🔄 Dynamic Inventory Deep Dive

### **How Dynamic Inventory Works:**

#### **1. AWS Tag-Based Discovery:**
```yaml
# /etc/ansible/inventories/aws_ec2.yml
plugin: aws_ec2
regions:
  - us-east-1
keyed_groups:
  - key: tags.Type
    prefix: type
  - key: tags.Role
    prefix: role
compose:
  ansible_host: public_ip_address | default(private_ip_address)
```

#### **2. Automatic Grouping:**
- `type_Jenkins_Master`: All Jenkins master instances
- `type_Jenkins_Agent`: All Jenkins agent instances
- `role_Configuration_Management`: Ansible controllers
- `role_CI_CD_Controller`: Jenkins masters
- `role_CI_CD_Worker`: Jenkins agents

#### **3. Inventory Update Automation:**
```bash
# Cron job runs every 5 minutes
*/5 * * * * /home/ubuntu/inventory_updater.sh update

# Manual update options
/home/ubuntu/inventory_updater.sh update    # Update inventory only
/home/ubuntu/inventory_updater.sh test      # Test connectivity
/home/ubuntu/inventory_updater.sh setup     # Configure new agents
/home/ubuntu/inventory_updater.sh full      # Do everything
```

### **Benefits of Dynamic Inventory:**
- ✅ **Zero Manual Maintenance**: No need to update host files
- ✅ **Auto-Discovery**: New instances automatically found
- ✅ **Tag-Based Grouping**: Logical organization of hosts
- ✅ **Multi-Region Support**: Can discover across regions
- ✅ **Real-Time Updates**: Always current with AWS state

---

## 🚨 Troubleshooting Common Issues

### **Issue 1: Jenkins Fails to Start**
**Symptoms:** Jenkins service fails with exit code 1
**Cause:** Java version incompatibility (Jenkins needs Java 17+)
**Solution:**
```bash
# Run Java 17 fix playbook
ansible-playbook /home/ubuntu/playbooks/jenkins-java17-fix.yml
```

### **Issue 2: Ansible Can't Connect**
**Symptoms:** "UNREACHABLE" errors, SSH failures
**Cause:** SSH key issues or network problems
**Solution:**
```bash
# Check SSH key
ls -la ~/.ssh/ansible_key.pem

# Test direct SSH
ssh -i ~/.ssh/ansible_key.pem ubuntu@<target_ip>

# Update inventory
/home/ubuntu/inventory_updater.sh update
```

### **Issue 3: Empty Inventory**
**Symptoms:** "provided hosts list is empty"
**Cause:** AWS CLI not configured or instances not tagged
**Solution:**
```bash
# Check AWS access
aws sts get-caller-identity

# Update inventory manually
/home/ubuntu/inventory_updater.sh update

# Verify instance tags
aws ec2 describe-instances --filters "Name=tag:Type,Values=Jenkins Master"
```

### **Issue 4: New Agents Not Configured**
**Symptoms:** New agents not in inventory or not configured
**Solution:**
```bash
# Force inventory update
/home/ubuntu/inventory_updater.sh full

# Configure new agents
ansible-playbook /home/ubuntu/playbooks/jenkins-agents.yml --limit jenkins_agents
```

---

## 🎯 Best Practices

### **Development Workflow:**
1. **Test Changes**: Use dev environment first
2. **Version Control**: Keep Terraform code in Git
3. **State Management**: Use remote state for team collaboration
4. **Documentation**: Update this guide with changes

### **Production Considerations:**
```hcl
# Production settings in prod.tfvars
jenkins_master_instance_type = "t3.large"
jenkins_agent_instance_type = "t3.large"
jenkins_agents_count = 3
allowed_ssh_cidr = "YOUR_OFFICE_IP/32"  # Restrict SSH access
```

### **Cost Optimization:**
- Use t2/t3 instances for development
- Enable S3 lifecycle policies
- Monitor CloudWatch costs
- Stop instances when not needed

### **Security Hardening:**
- Regular security updates
- Restrict security group rules
- Enable VPC Flow Logs
- Use IAM roles instead of access keys

---

## 🔮 Future Enhancements

### **Planned Features:**
- **EKS Integration**: Kubernetes cluster for container deployments
- **Multi-Region Support**: Cross-region disaster recovery
- **Auto Scaling**: Dynamic instance scaling based on load
- **Blue-Green Deployments**: Zero-downtime deployment strategies

### **Integration Possibilities:**
- **SonarQube**: Code quality analysis
- **Artifactory**: Artifact repository
- **Prometheus/Grafana**: Advanced monitoring
- **Vault**: Secrets management

---

## 📞 Support and Maintenance

### **Regular Tasks:**
```bash
# Weekly health check
ansible all -m ping
ansible all -m shell -a "df -h && free -h"

# Monthly updates
ansible all -m apt -a "update_cache=yes upgrade=yes" --become

# Quarterly reviews
# - Review CloudWatch costs
# - Update Jenkins plugins
# - Security audit
```

### **Emergency Procedures:**
```bash
# If Jenkins is down
ansible-playbook /home/ubuntu/playbooks/jenkins-master.yml

# If agents are unreachable
/home/ubuntu/inventory_updater.sh full

# If infrastructure needs rebuild
terraform destroy -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

---

## 📈 Success Metrics

### **Infrastructure Health:**
- ✅ All instances pingable via Ansible
- ✅ Jenkins UI accessible on port 8080
- ✅ Dynamic inventory discovering all instances
- ✅ CloudWatch monitoring active
- ✅ S3 buckets configured and accessible

### **Automation Success:**
- ✅ Zero manual configuration required
- ✅ New agents automatically discovered and configured
- ✅ SSH key management fully automated
- ✅ Playbooks execute successfully
- ✅ Monitoring and alerting functional

---

## 🎉 Conclusion

This setup provides a **fully automated, scalable, and secure CI/CD infrastructure** that:

- **Deploys in minutes** with a single Terraform command
- **Scales automatically** when new agents are added
- **Maintains itself** through dynamic inventory and cron jobs
- **Monitors continuously** with CloudWatch integration
- **Follows best practices** for security and reliability

The combination of Terraform for infrastructure and Ansible for configuration management creates a powerful, maintainable, and scalable DevOps platform.

---

**Last Updated:** August 13, 2025  
**Version:** 1.0  
**Author:** DevOps Team