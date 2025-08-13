# Complete Infrastructure Overview - DevOps Project 06

## 🏗️ Architecture Overview

This Terraform configuration creates a comprehensive CI/CD pipeline infrastructure on AWS with **94 resources** across multiple modules.

---

## 📋 Infrastructure Components

### 1. **VPC Module** (`modules/vpc/`)
**Creates the network foundation:**

#### Resources Created:
- **1 VPC** (`10.0.0.0/16`) with DNS support
- **2 Public Subnets** (`10.0.1.0/24`, `10.0.2.0/24`) across 2 AZs
- **2 Private Subnets** (`10.0.10.0/24`, `10.0.20.0/24`) across 2 AZs
- **1 Internet Gateway** for public internet access
- **2 NAT Gateways** (one per AZ) for private subnet internet access
- **2 Elastic IPs** for NAT Gateways
- **3 Route Tables** (1 public, 2 private)
- **4 Route Table Associations**
- **VPC Flow Logs** with CloudWatch integration
- **IAM Role & Policy** for Flow Logs

#### What it does:
- Creates isolated network environment
- Enables high availability across 2 availability zones
- Provides secure private subnets for Jenkins agents
- Enables internet access for all instances via NAT/IGW

---

### 2. **Security Groups Module** (`modules/security-groups/`)
**Creates network security controls:**

#### Resources Created:
- **Common Security Group**: SSH + internal VPC communication
- **Ansible Controller SG**: HTTP/HTTPS + Ansible ports (5986)
- **Jenkins Master SG**: Jenkins UI (8080) + Agent communication (50000)
- **Jenkins Agent SG**: Communication with master + Docker (2376) + SonarQube (9000)
- **EKS Additional SG**: Kubernetes API (443) + NodePort range (30000-32767)
- **ALB Security Group**: HTTP/HTTPS for load balancers
- **Database Security Group**: MySQL (3306) + PostgreSQL (5432)

#### What it does:
- Implements least privilege network access
- Allows only required ports and protocols
- Enables secure communication between components
- Prepares for future EKS and database integration

---

### 3. **IAM Module** (`modules/iam/`)
**Creates identity and access management:**

#### Resources Created:
- **Ansible Controller Role**: EC2 + SSM + S3 permissions
- **Jenkins Master Role**: EC2 + EKS + ECR + S3 permissions
- **Jenkins Agent Role**: ECR + EKS + S3 permissions for builds/deployments
- **EKS Cluster Role**: EKS cluster management permissions
- **EKS Node Group Role**: Worker node permissions
- **6 IAM Policies**: Custom policies for each role
- **3 Instance Profiles**: For EC2 instances
- **5 Policy Attachments**: AWS managed policies

#### What it does:
- Enables secure AWS API access for all instances
- Allows Jenkins to deploy to EKS clusters
- Enables Docker image push/pull from ECR
- Provides S3 access for artifacts and logs

---

### 4. **S3 Module** (`modules/s3/`)
**Creates storage for artifacts and state:**

#### Resources Created:
- **Artifacts Bucket**: Stores build artifacts, Docker images metadata
- **Terraform State Bucket**: Remote state storage (optional)
- **Logs Bucket**: Application and system logs storage
- **3 Bucket Versioning Configs**: Version control for all buckets
- **3 Encryption Configs**: AES256 encryption for all buckets
- **3 Public Access Blocks**: Prevents accidental public access
- **2 Lifecycle Policies**: Automated archival and cleanup
- **1 DynamoDB Table**: Terraform state locking

#### What it does:
- Provides secure storage for CI/CD artifacts
- Enables Terraform remote state management
- Implements automated log archival and cost optimization
- Ensures data encryption and access control

---

### 5. **EC2 Module** (`modules/ec2/`)
**Creates compute instances for CI/CD pipeline:**

#### Resources Created:
- **1 Ansible Controller** (t3.medium) in public subnet
- **1 Jenkins Master** (t3.large) in public subnet  
- **2 Jenkins Agents** (t3.medium) in private subnets
- **2 Elastic IPs** for Ansible Controller and Jenkins Master
- **1 SSH Key Pair** for inter-instance communication
- **1 TLS Private Key** (auto-generated if not provided)
- **3 SSM Parameters**: Private key + instance IPs for discovery

#### Instance Configurations:
**Ansible Controller:**
- **Location**: Public subnet (internet accessible)
- **Purpose**: Configuration management and automation
- **Tools Installed**: Ansible, Docker, kubectl, Helm, Terraform
- **Storage**: 30GB encrypted EBS volume

**Jenkins Master:**
- **Location**: Public subnet (web UI accessible)
- **Purpose**: CI/CD orchestration and job management
- **Tools Installed**: Jenkins, Java 11, Docker, Maven, kubectl, Helm
- **Storage**: 50GB encrypted EBS volume
- **Ports**: 8080 (Web UI), 50000 (Agent communication)

**Jenkins Agents (2 instances):**
- **Location**: Private subnets (secure build environment)
- **Purpose**: Build execution and deployment tasks
- **Tools Installed**: Java 11, Docker, Maven, Gradle, Node.js, Python, AWS CLI v2, kubectl, Helm, Terraform, SonarQube Scanner, Trivy, OWASP Dependency Check
- **Storage**: 40GB root + 50GB additional EBS volume for Docker

---

### 6. **Monitoring Module** (`modules/monitoring/`)
**Creates comprehensive monitoring and alerting:**

#### Resources Created:
- **1 SNS Topic**: Alert notifications
- **Email Subscriptions**: Based on `alert_email_addresses` variable
- **3 CloudWatch Log Groups**: For Jenkins Master, Agents, and Ansible Controller
- **8 CloudWatch Alarms**: CPU, Memory, Disk, Status checks
- **1 Composite Alarm**: Overall system health
- **1 CloudWatch Dashboard**: Real-time infrastructure overview
- **1 EventBridge Rule**: EC2 state change notifications
- **2 CloudWatch Insights Queries**: Error analysis and build failures
- **1 SSM Parameter**: CloudWatch agent configuration

#### Monitoring Coverage:
- **System Metrics**: CPU, Memory, Disk utilization
- **Jenkins Metrics**: Queue length, build failures, success rates
- **Instance Health**: Status checks and availability
- **Log Analysis**: Error detection and troubleshooting
- **Alert Thresholds**: Configurable warning and critical levels

---

## 🔄 Automated Setup Scripts

### 1. **Ansible Controller Setup** (`ansible_controller.sh`)
**What it installs:**
```bash
# System Updates & Essential Tools
- Ubuntu system updates
- curl, wget, git, vim, htop, tree, unzip
- Python 3, pip, venv
- AWS CLI v1

# Ansible & Configuration Management
- Ansible (latest from PPA)
- Python packages: boto3, botocore, ansible-core, jmespath, netaddr
- Ansible configuration files and inventory setup
- Dynamic AWS EC2 inventory configuration

# Container & Orchestration Tools  
- Docker and Docker Compose
- kubectl (latest stable)
- Helm package manager
- Terraform

# Automation & Playbooks
- Sample Jenkins installation playbook
- SSH key generation for passwordless authentication
- Welcome message and system info scripts
- CloudWatch agent for monitoring
```

### 2. **Jenkins Master Setup** (`jenkins_master.sh`)
**What it installs:**
```bash
# Core Jenkins Setup
- Java 11 OpenJDK (Jenkins requirement)
- Jenkins (latest stable from official repository)
- Jenkins plugins: Pipeline, Docker, AWS, Kubernetes, SonarQube, Artifactory, BlueOcean
- Initial admin user (admin/admin123)
- Security configuration and access controls

# Build & Development Tools
- Docker and Docker Compose
- Maven build tool
- Node.js 18 and npm
- AWS CLI v2
- Terraform

# Kubernetes & Container Tools
- kubectl (latest stable)
- Helm package manager

# Monitoring & Configuration
- CloudWatch agent for log collection
- Jenkins service optimization
- Firewall configuration
- Status check scripts
```

### 3. **Jenkins Agent Setup** (`jenkins_agent.sh`)
**What it installs:**
```bash
# Build Environment
- Java 11 OpenJDK
- Maven and Gradle build tools
- Node.js 18 and npm
- Python 3 and pip

# Container & Deployment Tools
- Docker and Docker Compose (with additional storage volume)
- kubectl and Helm
- AWS CLI v2
- Terraform

# Security & Quality Tools
- SonarQube Scanner (code quality analysis)
- Trivy (container security scanning)
- OWASP Dependency Check (vulnerability scanning)

# System Configuration
- Jenkins agent user and service setup
- Additional 50GB EBS volume for Docker storage
- Docker daemon configuration for optimal performance
- CloudWatch agent for monitoring
- Build workspace preparation
```

---

## 🚀 Deployment Flow

### **Phase 1: Network Foundation**
1. **VPC Creation**: Isolated network environment
2. **Subnet Creation**: Public/private subnet separation
3. **Gateway Setup**: Internet and NAT gateways for connectivity
4. **Route Configuration**: Traffic routing between subnets

### **Phase 2: Security Setup**
1. **Security Groups**: Network-level firewall rules
2. **IAM Roles**: AWS API access permissions
3. **Key Management**: SSH keys for instance communication

### **Phase 3: Storage Setup**
1. **S3 Buckets**: Artifact and log storage
2. **Encryption**: Data protection at rest
3. **Lifecycle Policies**: Cost optimization

### **Phase 4: Compute Deployment**
1. **Ansible Controller**: Configuration management server
2. **Jenkins Master**: CI/CD orchestration server
3. **Jenkins Agents**: Build and deployment workers

### **Phase 5: Monitoring Setup**
1. **CloudWatch Integration**: Metrics and log collection
2. **Alert Configuration**: Email notifications for issues
3. **Dashboard Creation**: Real-time infrastructure overview

---

## 🔧 What Each Script Does

### **User Data Scripts Execution Timeline:**

#### **Boot Time (0-5 minutes):**
- System updates and package installations
- Hostname configuration
- Essential tool installations

#### **Service Setup (5-15 minutes):**
- Jenkins/Ansible installation and configuration
- Docker setup and user permissions
- Service startup and enablement

#### **Tool Installation (15-25 minutes):**
- Development tools (Maven, Gradle, Node.js)
- Cloud tools (AWS CLI, kubectl, Helm)
- Security tools (SonarQube Scanner, Trivy)

#### **Configuration (25-30 minutes):**
- Jenkins plugin installation and configuration
- CloudWatch agent setup
- SSH key distribution
- Welcome messages and helper scripts

---

## 📊 Resource Summary

### **By Service:**
- **EC2**: 4 instances + 2 Elastic IPs + 1 Key Pair
- **VPC**: 1 VPC + 4 subnets + 3 route tables + 1 IGW + 2 NAT GW
- **Security**: 7 security groups + 6 IAM roles + 6 policies
- **Storage**: 3 S3 buckets + 1 DynamoDB table
- **Monitoring**: 8 alarms + 1 dashboard + 1 SNS topic + 3 log groups

### **By Environment:**
- **Development**: 94 resources, optimized for learning and testing
- **Production**: Same architecture, larger instance types and enhanced monitoring

---

## 🎯 End-to-End Workflow

### **1. Infrastructure Deployment:**
```bash
terraform apply -var-file="environments/dev.tfvars"
```

### **2. Automatic Configuration:**
- All instances self-configure via user data scripts
- Jenkins Master becomes accessible at `http://JENKINS_IP:8080`
- Ansible Controller ready for playbook execution
- Jenkins Agents automatically register with master

### **3. Manual Configuration Steps:**
- Access Jenkins UI and change default password
- Configure GitHub/GitLab credentials
- Set up SonarQube and JFrog Artifactory integration
- Create CI/CD pipeline jobs

### **4. Monitoring Access:**
- CloudWatch Dashboard: Real-time metrics
- Email Alerts: Automatic notifications
- Log Analysis: Centralized log management

---

## 🔍 Key Features

### **High Availability:**
- Multi-AZ deployment across 2 availability zones
- Redundant NAT Gateways for private subnet internet access
- Load balancer ready architecture

### **Security:**
- Network segmentation with public/private subnets
- Least privilege IAM roles and policies
- Encrypted storage for all data
- Security group rules with minimal required access

### **Scalability:**
- Modular design for easy expansion
- Auto-scaling ready architecture
- Container-ready with Docker and Kubernetes tools

### **Monitoring:**
- Comprehensive CloudWatch integration
- Real-time alerting and notifications
- Log aggregation and analysis
- Performance metrics and dashboards

### **Automation:**
- Infrastructure as Code with Terraform
- Automated instance configuration
- CI/CD pipeline ready
- Configuration management with Ansible

---

## 💰 Cost Optimization

### **Development Environment:**
- **EC2**: ~$150/month (4 instances)
- **NAT Gateways**: ~$90/month (2 gateways)
- **Storage**: ~$20/month (S3 + EBS)
- **Monitoring**: ~$10/month (CloudWatch)
- **Total**: ~$270/month

### **Cost Saving Tips:**
- Use Spot instances for Jenkins agents
- Schedule instances to stop during non-work hours
- Implement S3 lifecycle policies for log archival
- Use single NAT Gateway for development

---

## 🚀 Post-Deployment Access

### **Instance Access:**
```bash
# Ansible Controller
ssh -i cicd-pipeline-key.pem ubuntu@<ansible-controller-ip>

# Jenkins Master  
ssh -i cicd-pipeline-key.pem ubuntu@<jenkins-master-ip>
# Web UI: http://<jenkins-master-ip>:8080
```

### **Service URLs:**
- **Jenkins**: `http://<jenkins-master-ip>:8080` (admin/admin123)
- **Monitoring**: CloudWatch Dashboard URL in outputs
- **Logs**: CloudWatch Log Groups for each service

### **Verification Commands:**
```bash
# Check Jenkins status
ssh -i key.pem ubuntu@<jenkins-ip>
./check-jenkins.sh

# Check Ansible
ssh -i key.pem ubuntu@<ansible-ip>
ansible --version
ansible all -i /etc/ansible/inventories/aws_ec2.yml -m ping

# Check monitoring
aws cloudwatch describe-alarms
aws logs describe-log-groups
```

---

## 🔄 CI/CD Pipeline Ready

### **Tools Pre-installed:**
- **Source Control**: Git
- **Build Tools**: Maven, Gradle, npm
- **Container Tools**: Docker, Docker Compose
- **Deployment Tools**: kubectl, Helm, Terraform
- **Quality Tools**: SonarQube Scanner, Trivy, OWASP Dependency Check
- **Cloud Tools**: AWS CLI v2, IAM roles configured

### **Jenkins Plugins Auto-installed:**
- Pipeline and Blue Ocean for modern CI/CD
- Docker plugins for container builds
- AWS plugins for cloud deployments
- Kubernetes plugins for container orchestration
- SonarQube plugins for code quality
- Artifactory plugins for artifact management

### **Ready for Integration:**
- **GitHub/GitLab**: Source code management
- **SonarQube Cloud**: Code quality analysis
- **JFrog Artifactory**: Artifact repository
- **Docker Registry**: Container image storage
- **Kubernetes**: Application deployment target

---

## 🛡️ Security Features

### **Network Security:**
- Private subnets for build agents
- Security groups with minimal required access
- VPC Flow Logs for network monitoring
- No direct internet access for private instances

### **Data Security:**
- Encrypted EBS volumes for all instances
- Encrypted S3 buckets with lifecycle policies
- IAM roles with least privilege access
- SSH key management and distribution

### **Monitoring Security:**
- CloudWatch agent with secure log collection
- Alert notifications for security events
- Audit trails for all infrastructure changes
- Compliance-ready logging and monitoring

---

## 📈 Scalability & Extensibility

### **Horizontal Scaling:**
- Add more Jenkins agents by increasing `jenkins_agents_count`
- Multi-region deployment by duplicating configuration
- Auto Scaling Groups integration ready

### **Vertical Scaling:**
- Increase instance types in environment configs
- Add more storage volumes as needed
- Upgrade to larger RDS instances for databases

### **Feature Extensions:**
- EKS cluster integration (module ready)
- Database integration (RDS module ready)
- Load balancer integration (ALB security groups ready)
- Multi-environment deployment (staging, prod configs)

---

## 🎯 Success Indicators

### **Infrastructure Deployed Successfully When:**
- ✅ Terraform apply completes without errors
- ✅ All 94 resources created successfully
- ✅ Jenkins Master accessible at port 8080
- ✅ Ansible Controller can ping all instances
- ✅ CloudWatch dashboard shows metrics
- ✅ Email alerts configured and working

### **Services Ready When:**
- ✅ Jenkins shows "Jenkins is fully up and running"
- ✅ All Jenkins agents connected and online
- ✅ Ansible can execute playbooks on all nodes
- ✅ Docker daemon running on all instances
- ✅ CloudWatch agent collecting metrics and logs

---

## 🔧 Troubleshooting Guide

### **Common Issues:**
1. **AMI Not Found**: Region-specific AMI availability
2. **Key Pair Missing**: Create EC2 key pair first
3. **Insufficient Permissions**: Check IAM user permissions
4. **Resource Limits**: Check AWS service quotas
5. **Network Connectivity**: Verify security group rules

### **Diagnostic Commands:**
```bash
# Check Terraform state
terraform state list
terraform output

# Check AWS resources
aws ec2 describe-instances
aws ec2 describe-security-groups
aws s3 ls

# Check services
ssh -i key.pem ubuntu@<ip> "systemctl status jenkins"
ssh -i key.pem ubuntu@<ip> "docker ps"
```

---

This infrastructure provides a **production-ready foundation** for advanced CI/CD pipelines with comprehensive monitoring, security, and automation capabilities! 🚀