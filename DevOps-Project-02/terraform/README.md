# Scalable VPC Architecture on AWS

This Terraform configuration deploys a modular and scalable VPC architecture on AWS as per the project requirements.

## Architecture Overview

- **Two VPCs**: Bastion VPC (192.168.0.0/16) and Application VPC (172.32.0.0/16)
- **Transit Gateway**: For private communication between VPCs
- **Auto Scaling Group**: Min: 2, Max: 4 instances with Network Load Balancer
- **Security Groups**: Proper security controls for bastion and application tiers
- **VPC Flow Logs**: Enabled for both VPCs with CloudWatch integration
- **S3 Bucket**: For application configuration storage
- **IAM Roles**: Least privilege access for EC2 instances

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Golden AMI created with required dependencies:
   - AWS CLI
   - Apache Web Server
   - Git
   - CloudWatch Agent
   - AWS SSM Agent
4. EC2 Key Pair created
5. Domain name (optional for Route53 configuration)

## Module Structure

```
terraform/
├── main.tf                    # Main configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example configuration
└── modules/
    ├── vpc/                   # VPC with subnets, NAT, IGW, Flow Logs
    ├── security-groups/       # Security groups for all tiers
    ├── iam/                   # IAM roles and policies
    ├── ec2/                   # EC2 instances (bastion host)
    ├── autoscaling/           # ASG with launch template
    ├── load-balancer/         # Network Load Balancer
    ├── s3/                    # S3 bucket for app config
    └── transit-gateway/       # Transit Gateway for VPC connectivity
```

## Deployment Steps

1. **Clone and Navigate**:
   ```bash
   cd terraform/
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan Deployment**:
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

6. **Upload Application Code to S3**:
   ```bash
   aws s3 sync ../html-web-app/ s3://YOUR_BUCKET_NAME/html-web-app/
   ```

## Configuration

### Required Variables

Update `terraform.tfvars` with your specific values:

- `golden_ami_id`: Your Golden AMI ID
- `key_pair_name`: Your EC2 Key Pair name
- `domain_name`: Your domain for Route53 (optional)

### Optional Customizations

- Modify CIDR blocks in `variables.tf`
- Adjust instance types and scaling parameters
- Update security group rules as needed
- Modify CloudWatch alarm thresholds

## Validation

1. **SSH to Bastion Host**:
   ```bash
   ssh -i your-key.pem ec2-user@BASTION_PUBLIC_IP
   ```

2. **SSH to Private Instances via Bastion**:
   ```bash
   ssh -i your-key.pem ec2-user@PRIVATE_INSTANCE_IP
   ```

3. **Access via Session Manager**:
   - Use AWS Console → Systems Manager → Session Manager

4. **Test Web Application**:
   - Access via Load Balancer DNS name
   - Verify application loads correctly

## Security Features

- **Network Segmentation**: Separate VPCs for different tiers
- **Security Groups**: Restrictive rules with least privilege
- **Private Subnets**: Application instances in private subnets
- **NAT Gateway**: Secure outbound internet access
- **IAM Roles**: Minimal required permissions
- **Encryption**: EBS volumes encrypted
- **VPC Flow Logs**: Network traffic monitoring

## Monitoring

- **CloudWatch Alarms**: CPU-based auto scaling
- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch Agent**: Custom metrics collection
- **Target Group Health Checks**: Application health monitoring

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

## Best Practices Implemented

1. **Modular Design**: Reusable modules for different components
2. **Least Privilege**: Minimal IAM permissions
3. **High Availability**: Multi-AZ deployment
4. **Auto Scaling**: Dynamic capacity management
5. **Monitoring**: Comprehensive logging and alerting
6. **Security**: Defense in depth approach
7. **Documentation**: Clear README and variable descriptions
8. **Version Control**: Terraform state management ready

## Troubleshooting

- Check CloudWatch logs for application issues
- Verify security group rules for connectivity problems
- Ensure Golden AMI has all required software installed
- Check IAM permissions for S3 access issues