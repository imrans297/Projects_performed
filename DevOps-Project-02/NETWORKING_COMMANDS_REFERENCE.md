# Networking & AWS Commands Reference Guide

## AWS CLI Commands for Infrastructure Management

### 1. VPC & Networking Commands

#### VPC Information
```bash
# List all VPCs
aws ec2 describe-vpcs

# Get specific VPC details
aws ec2 describe-vpcs --vpc-ids vpc-05cc9c679fcf38e55

# List subnets in a VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-05cc9c679fcf38e55"

# Get route tables for a VPC
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-05cc9c679fcf38e55"

# Check Internet Gateways
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-05cc9c679fcf38e55"

# Check NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-05cc9c679fcf38e55"
```

#### Security Groups
```bash
# List security groups
aws ec2 describe-security-groups

# Get specific security group
aws ec2 describe-security-groups --group-ids sg-0cb6bb4c8b02be5d0

# Check security group rules
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=sg-0cb6bb4c8b02be5d0"
```

### 2. Transit Gateway Commands

#### Transit Gateway Information
```bash
# List Transit Gateways
aws ec2 describe-transit-gateways

# Get Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments

# Check Transit Gateway route tables
aws ec2 describe-transit-gateway-route-tables

# Search routes in Transit Gateway route table
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id tgw-rtb-01d0331a052f1a2a4 \
  --filters "Name=state,Values=active"

# Get Transit Gateway VPC attachments
aws ec2 describe-transit-gateway-vpc-attachments
```

### 3. EC2 Instance Commands

#### Instance Information
```bash
# List all instances
aws ec2 describe-instances

# Get specific instance details
aws ec2 describe-instances --instance-ids i-0366fb81d426d8e91

# Get instance private IP
aws ec2 describe-instances --instance-ids i-0366fb81d426d8e91 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text

# Get instance public IP
aws ec2 describe-instances --instance-ids i-0366fb81d426d8e91 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Get instance VPC and subnet info
aws ec2 describe-instances --instance-ids i-0366fb81d426d8e91 \
  --query 'Reservations[0].Instances[0].[VpcId,SubnetId,SecurityGroups[0].GroupId]' --output table
```

### 4. Auto Scaling Group Commands

#### ASG Information
```bash
# List Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups

# Get specific ASG details
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "dev-scalable-vpc-arch-asg"

# Get ASG instances with status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "dev-scalable-vpc-arch-asg" \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' --output table

# Terminate instance in ASG
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id i-0366fb81d426d8e91 \
  --no-should-decrement-desired-capacity
```

### 5. Load Balancer Commands

#### Load Balancer Information
```bash
# List Network Load Balancers
aws elbv2 describe-load-balancers

# Get target groups
aws elbv2 describe-target-groups

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:195275652425:targetgroup/dev-scalable-vpc-arch-tg/3be9ee99af4982cc

# Get load balancer listeners
aws elbv2 describe-listeners \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:195275652425:loadbalancer/net/scalable-vpc-arch-nlb/af2bfba364265030
```

### 6. S3 Commands

#### S3 Bucket Operations
```bash
# List S3 buckets
aws s3 ls

# List contents of specific bucket
aws s3 ls s3://scalable-vpc-arch-app-config-fdb9de83/

# List web app files
aws s3 ls s3://scalable-vpc-arch-app-config-fdb9de83/html-web-app/ --recursive

# Sync local files to S3
aws s3 sync html-web-app/ s3://scalable-vpc-arch-app-config-fdb9de83/html-web-app/

# Copy single file to S3
aws s3 cp index.html s3://scalable-vpc-arch-app-config-fdb9de83/html-web-app/

# Download file from S3
aws s3 cp s3://scalable-vpc-arch-app-config-fdb9de83/html-web-app/index.html ./
```

### 7. Systems Manager (SSM) Commands

#### Session Manager
```bash
# Start session with instance
aws ssm start-session --target i-0366fb81d426d8e91

# List available instances for Session Manager
aws ssm describe-instance-information

# Send command to instance
aws ssm send-command \
  --instance-ids i-0366fb81d426d8e91 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["ping -c 3 172.32.10.253"]'

# Get command result
aws ssm get-command-invocation \
  --command-id b7707f16-3bf0-4b75-9c1f-e3a4f395b7ae \
  --instance-id i-0366fb81d426d8e91
```

---

## Linux Networking Commands (Run inside instances via SSM)

### 1. Network Interface Information
```bash
# Show network interfaces
ip addr show
ifconfig

# Show routing table
ip route
route -n

# Show network statistics
netstat -i
ss -i
```

### 2. Connectivity Testing
```bash
# Ping test
ping -c 3 172.32.10.253
ping -c 3 google.com

# Test specific port
telnet 172.32.10.253 22
telnet 172.32.10.253 80

# Test HTTP connectivity
curl http://172.32.10.253
curl -I http://172.32.10.253

# Test DNS resolution
nslookup google.com
dig google.com
```

### 3. Port and Service Information
```bash
# Show listening ports
netstat -tlnp
ss -tlnp

# Show all network connections
netstat -an
ss -an

# Check specific port
netstat -tlnp | grep :80
ss -tlnp | grep :80

# Show processes using network
lsof -i
```

### 4. System Network Configuration
```bash
# Show DNS configuration
cat /etc/resolv.conf

# Show network configuration files
cat /etc/netplan/*.yaml  # Ubuntu 18+
cat /etc/network/interfaces  # Older Ubuntu

# Show hostname and domain
hostname
hostname -f
```

### 5. Firewall and Security
```bash
# Check iptables rules
sudo iptables -L
sudo iptables -L -n -v

# Check UFW status (Ubuntu)
sudo ufw status

# Show SELinux status (if applicable)
sestatus
```

---

## Web Server Testing Commands

### 1. Apache/HTTP Testing
```bash
# Check Apache status
sudo systemctl status apache2
sudo systemctl status httpd

# Test web server locally
curl http://localhost
curl http://127.0.0.1
curl -I http://localhost

# Check Apache configuration
sudo apache2ctl configtest
sudo httpd -t

# View Apache logs
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log
```

### 2. File System Checks
```bash
# Check web root directory
ls -la /var/www/html/
ls -la /var/www/html/html-web-app/

# Check file permissions
ls -la /var/www/html/index.html

# Check disk space
df -h
du -sh /var/www/html/
```

### 3. Process and Service Management
```bash
# Check running processes
ps aux | grep apache
ps aux | grep httpd

# Check system services
systemctl list-units --type=service --state=running

# Restart web server
sudo systemctl restart apache2
sudo systemctl reload apache2
```

---

## AWS Instance Metadata Commands

### 1. Instance Information
```bash
# Get instance ID
curl http://169.254.169.254/latest/meta-data/instance-id

# Get instance type
curl http://169.254.169.254/latest/meta-data/instance-type

# Get private IP
curl http://169.254.169.254/latest/meta-data/local-ipv4

# Get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Get availability zone
curl http://169.254.169.254/latest/meta-data/placement/availability-zone
```

### 2. Security and IAM
```bash
# Get security groups
curl http://169.254.169.254/latest/meta-data/security-groups

# Get IAM role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Get user data
curl http://169.254.169.254/latest/user-data
```

---

## Terraform Commands

### 1. Basic Operations
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"

# Show outputs
terraform output

# Show state
terraform state list
terraform state show resource_name
```

### 2. Targeted Operations
```bash
# Apply specific resource
terraform apply -target=module.asg -var-file="environments/dev.tfvars"

# Import existing resource
terraform import 'module.bastion_vpc.aws_cloudwatch_log_group.vpc_flow_logs[0]' '/aws/vpc/flowlogs/log-group-name'

# Refresh state
terraform refresh -var-file="environments/dev.tfvars"
```

### 3. Troubleshooting
```bash
# Force unlock state
terraform force-unlock LOCK_ID

# Show detailed logs
TF_LOG=DEBUG terraform apply

# Remove resource from state
terraform state rm resource_name
```

---

## Quick Diagnostic Scripts

### 1. Network Connectivity Test Script
```bash
#!/bin/bash
echo "=== Network Connectivity Test ==="
echo "Local IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo ""
echo "Testing connectivity..."
ping -c 3 8.8.8.8
echo ""
echo "Testing web server..."
curl -I http://localhost
echo ""
echo "Listening ports:"
netstat -tlnp
```

### 2. AWS Resource Status Script
```bash
#!/bin/bash
echo "=== AWS Resource Status ==="
echo "VPCs:"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table
echo ""
echo "Transit Gateways:"
aws ec2 describe-transit-gateways --query 'TransitGateways[*].[TransitGatewayId,State]' --output table
echo ""
echo "Load Balancers:"
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' --output table
```

---

## Common Troubleshooting Workflows

### 1. Web Application Not Working
```bash
# Step 1: Check instance health
aws ec2 describe-instances --instance-ids i-xxx
aws ssm start-session --target i-xxx

# Step 2: Check web server (in SSM session)
sudo systemctl status apache2
curl http://localhost
ls -la /var/www/html/

# Step 3: Check load balancer
aws elbv2 describe-target-health --target-group-arn arn:aws:...
curl http://load-balancer-dns-name
```

### 2. Cross-VPC Connectivity Issues
```bash
# Step 1: Check Transit Gateway
aws ec2 describe-transit-gateway-attachments
aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id tgw-rtb-xxx

# Step 2: Check VPC route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxx"

# Step 3: Test from instance (in SSM session)
ping target-ip
telnet target-ip 22
```

### 3. Auto Scaling Issues
```bash
# Step 1: Check ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names asg-name

# Step 2: Check instance health
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# Step 3: Force instance refresh
aws autoscaling terminate-instance-in-auto-scaling-group --instance-id i-xxx --no-should-decrement-desired-capacity
```

---

*This reference guide covers all networking and AWS commands used during the DevOps Project 02 implementation and troubleshooting.*