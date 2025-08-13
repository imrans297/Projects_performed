# Advanced CI/CD Pipeline Infrastructure

This Terraform configuration deploys a complete CI/CD pipeline infrastructure on AWS with best practices and modular design.

## 🏗️ Architecture Overview

The infrastructure includes:

- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **Ansible Controller**: Configuration management server
- **Jenkins Master**: CI/CD orchestration server
- **Jenkins Agents**: Build and deployment workers (2-3 instances)
- **Security Groups**: Least privilege network access
- **IAM Roles**: Minimal required permissions
- **S3 Buckets**: Artifacts, logs, and Terraform state storage
- **EKS Cluster**: Kubernetes deployment target (optional)

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **EC2 Key Pair** created in your target region

### Required AWS Permissions

Your AWS user/role needs permissions for:
- EC2 (instances, security groups, key pairs)
- VPC (networking components)
- IAM (roles and policies)
- S3 (buckets and objects)
- EKS (clusters and node groups)
- Systems Manager (parameter store)
- CloudWatch (logs and monitoring)

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
cd terraform/
```

### 2. Create EC2 Key Pair
```bash
# Create a new key pair (replace 'cicd-pipeline-key' with your preferred name)
aws ec2 create-key-pair --key-name cicd-pipeline-key --query 'KeyMaterial' --output text > ~/.ssh/cicd-pipeline-key.pem
chmod 400 ~/.ssh/cicd-pipeline-key.pem
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Plan Deployment
```bash
# For development environment
terraform plan -var-file="environments/dev.tfvars"

# For production environment
terraform plan -var-file="environments/prod.tfvars"
```

### 5. Deploy Infrastructure
```bash
# Deploy development environment
terraform apply -var-file="environments/dev.tfvars"

# Deploy production environment
terraform apply -var-file="environments/prod.tfvars"
```

## 📁 Project Structure

```
terraform/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variables
├── locals.tf                  # Local values and configurations
├── outputs.tf                 # Output values
├── README.md                  # This file
├── environments/              # Environment-specific configurations
│   ├── dev.tfvars            # Development environment
│   └── prod.tfvars           # Production environment
└── modules/                   # Reusable modules
    ├── vpc/                   # VPC and networking
    ├── security-groups/       # Security groups
    ├── iam/                   # IAM roles and policies
    ├── s3/                    # S3 buckets
    └── ec2/                   # EC2 instances
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── user_data/         # Instance initialization scripts
            ├── ansible_controller.sh
            ├── jenkins_master.sh
            └── jenkins_agent.sh
```

## 🔧 Configuration

### Environment Variables

Update the appropriate `.tfvars` file:

```hcl
# environments/dev.tfvars
aws_region   = "us-east-1"
environment  = "dev"
key_pair_name = "your-key-pair-name"

# Instance types
ansible_controller_instance_type = "t3.medium"
jenkins_master_instance_type     = "t3.large"
jenkins_agent_instance_type      = "t3.medium"
jenkins_agents_count             = 2
```

### Networking Configuration

```hcl
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
allowed_ssh_cidr        = "YOUR_IP/32"  # Restrict for security
```

## 🔐 Security Features

- **Network Segmentation**: Public/private subnet isolation
- **Security Groups**: Minimal required access
- **IAM Roles**: Least privilege permissions
- **Encrypted Storage**: EBS volumes and S3 buckets
- **VPC Flow Logs**: Network traffic monitoring
- **SSH Key Management**: Automated key distribution

## 📊 Monitoring and Logging

- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch Logs**: Application and system logs
- **S3 Lifecycle Policies**: Automated log archival
- **Instance Monitoring**: CloudWatch metrics

## 🔗 Access Information

After deployment, you'll get outputs including:

```bash
# SSH to Ansible Controller
ssh -i ~/.ssh/your-key.pem ubuntu@<ansible-controller-ip>

# SSH to Jenkins Master
ssh -i ~/.ssh/your-key.pem ubuntu@<jenkins-master-ip>

# Jenkins Web UI
http://<jenkins-master-ip>:8080
```

## 🛠️ Post-Deployment Steps

### 1. Configure Ansible Controller

```bash
# SSH to Ansible Controller
ssh -i ~/.ssh/your-key.pem ubuntu@<ansible-controller-ip>

# Check Ansible installation
ansible --version

# Test connectivity to Jenkins instances
ansible all -i /etc/ansible/inventories/aws_ec2.yml -m ping
```

### 2. Configure Jenkins Master

```bash
# Access Jenkins Web UI
http://<jenkins-master-ip>:8080

# Get initial admin password
ssh -i ~/.ssh/your-key.pem ubuntu@<jenkins-master-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 3. Configure Jenkins Agents

The agents are automatically configured to connect to the Jenkins master. You can verify the connection in the Jenkins UI under "Manage Jenkins" > "Manage Nodes".

## 🔄 CI/CD Pipeline Setup

### 1. Install Required Jenkins Plugins

The following plugins are automatically installed:
- Pipeline plugins
- Docker plugins
- AWS plugins
- Kubernetes plugins
- SonarQube plugins
- Artifactory plugins

### 2. Configure Jenkins Credentials

Add the following credentials in Jenkins:
- AWS credentials for deployments
- GitHub/GitLab credentials for source code
- Docker registry credentials
- SonarQube tokens
- Artifactory credentials

### 3. Create Pipeline Jobs

Example Jenkinsfile structure:
```groovy
pipeline {
    agent { label 'jenkins-agent' }
    
    stages {
        stage('Checkout') {
            steps {
                git 'your-repo-url'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f k8s-manifests/'
            }
        }
    }
}
```

## 🧹 Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

## 📈 Scaling and Optimization

### Development Environment
- Smaller instance types (t3.medium/large)
- Fewer Jenkins agents (2)
- Basic monitoring

### Production Environment
- Larger instance types (t3.large/xlarge)
- More Jenkins agents (3+)
- Enhanced monitoring and backup

## 🔍 Troubleshooting

### Common Issues

1. **Key Pair Not Found**
   ```bash
   # Create the key pair in AWS
   aws ec2 create-key-pair --key-name your-key-name
   ```

2. **Insufficient Permissions**
   - Ensure your AWS user has the required permissions
   - Check IAM policies and roles

3. **Instance Connection Issues**
   - Verify security group rules
   - Check VPC and subnet configurations
   - Ensure key pair is correctly specified

### Logs and Debugging

```bash
# Check instance user data logs
ssh -i ~/.ssh/your-key.pem ubuntu@<instance-ip>
sudo tail -f /var/log/cloud-init-output.log

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker logs
sudo journalctl -u docker -f
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS documentation
3. Check Terraform documentation
4. Open an issue in the repository

---

**Note**: This infrastructure is designed for learning and development purposes. For production use, consider additional security hardening, backup strategies, and compliance requirements.