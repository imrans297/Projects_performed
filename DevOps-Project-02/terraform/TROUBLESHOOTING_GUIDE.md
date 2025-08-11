# DevOps Project 02 - Troubleshooting Guide

## Project Overview
Scalable VPC Architecture with Transit Gateway, Auto Scaling, and Load Balancer deployed using Terraform.

---

## Common Issues & Solutions

### 1. Terraform Validation Errors

#### Issue: Missing required argument
```
Error: Missing required argument
The argument "name_prefix" is required, but no definition was found.
```

**Root Cause**: Module variable mismatch between module call and module definition.

**Solution**:
1. Check module variables.tf file
2. Update module call to match expected variables
3. Example fix:
```hcl
# Change from:
project_name = var.project_name
# To:
name_prefix = local.name_prefix
```

#### Issue: Unsupported argument
```
Error: Unsupported argument
An argument named "project_name" is not expected here.
```

**Solution**: Remove or rename the argument to match module expectations.

---

### 2. CloudWatch Log Group Already Exists

#### Issue:
```
Error: creating CloudWatch Logs Log Group: ResourceAlreadyExistsException
```

**Solutions**:

**Option 1: Import existing resources**
```bash
terraform import 'module.bastion_vpc.aws_cloudwatch_log_group.vpc_flow_logs[0]' '/aws/vpc/flowlogs/dev-scalable-vpc-arch-bastion-vpc'
terraform import 'module.app_vpc.aws_cloudwatch_log_group.vpc_flow_logs[0]' '/aws/vpc/flowlogs/dev-scalable-vpc-arch-app-vpc'
```

**Option 2: Add lifecycle rules**
```hcl
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  lifecycle {
    ignore_changes = [name]
  }
}
```

---

### 3. Security Group Cross-VPC References

#### Issue:
```
Error: You have specified two resources that belong to different networks.
```

**Root Cause**: Security group rules referencing security groups from different VPCs.

**Solution**: Use CIDR blocks instead of security group references for cross-VPC access:
```hcl
# Change from:
security_groups = [aws_security_group.bastion.id]
# To:
cidr_blocks = [var.bastion_vpc_cidr]
```

---

### 4. S3 File Upload Automation

#### Manual Method:
```bash
aws s3 sync html-web-app/ s3://bucket-name/html-web-app/
```

#### Terraform Automation:
Create s3-upload module:
```hcl
resource "aws_s3_object" "web_files" {
  for_each = fileset("${path.root}/../html-web-app", "**/*")
  
  bucket = var.bucket_name
  key    = "html-web-app/${each.value}"
  source = "${path.root}/../html-web-app/${each.value}"
  etag   = filemd5("${path.root}/../html-web-app/${each.value}")
  
  content_type = lookup(local.mime_types, 
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream"
  )
}
```

---

### 5. Transit Gateway Routing Issues

#### Issue: Cross-VPC connectivity not working
```bash
# Ping fails between VPCs
ping 172.32.10.253  # Times out
```

**Diagnosis Commands**:
```bash
# Check Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments

# Check Transit Gateway route tables
aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id tgw-rtb-xxx

# Check VPC route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxx"
```

**Solution**: Add Transit Gateway routes to VPC route tables:
```hcl
# Add to VPC module
resource "aws_route" "private_to_tgw" {
  count = var.transit_gateway_id != null ? length(aws_route_table.private) : 0
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = var.cross_vpc_cidr
  transit_gateway_id     = var.transit_gateway_id
}

# Add to public route table for bastion host
resource "aws_route" "public_to_tgw" {
  count = var.transit_gateway_id != null ? 1 : 0
  
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.cross_vpc_cidr
  transit_gateway_id     = var.transit_gateway_id
}
```

**Apply targeted changes**:
```bash
terraform apply -target=module.bastion_vpc.aws_route.private_to_tgw -auto-approve
terraform apply -target=module.bastion_vpc.aws_route.public_to_tgw -auto-approve
terraform apply -target=module.app_vpc.aws_route.private_to_tgw -auto-approve
```

---

### 6. SSH Access to Private Instances

#### Issue: SSH from bastion to private instances fails

**Diagnosis**:
```bash
# From bastion host
ping 172.32.10.253  # Check connectivity
telnet 172.32.10.253 22  # Check SSH port
```

**Solutions**:

**Option 1: Fix Transit Gateway routing** (see section 5)

**Option 2: Use AWS Session Manager** (Recommended)
```bash
# Connect directly to private instance
aws ssm start-session --target i-0366fb81d426d8e91

# Or via AWS Console: Systems Manager → Session Manager
```

**Option 3: SSH with ProxyJump**
```bash
ssh -i key.pem -J ubuntu@bastion-ip ubuntu@private-ip
```

---

### 7. Web Application Testing

#### Test from Private Instance (via SSM):
```bash
# Check Apache status
sudo systemctl status apache2

# Check files downloaded from S3
ls -la /var/www/html/

# Test locally
curl http://localhost
curl http://127.0.0.1

# Check listening ports
sudo netstat -tlnp | grep :80
```

#### Test from Internet:
```bash
# Test load balancer
curl http://load-balancer-dns-name.elb.amazonaws.com

# Or open in browser
http://load-balancer-dns-name.elb.amazonaws.com
```

---

### 8. Auto Scaling Group Issues

#### Check ASG Status:
```bash
# List instances in ASG
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "asg-name"

# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
```

#### Refresh Instances:
```bash
# Terminate instances to trigger replacement
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id i-xxx \
  --no-should-decrement-desired-capacity
```

---

### 9. Terraform State Lock Issues

#### Issue:
```
Error: Error acquiring the state lock
resource temporarily unavailable
```

**Solution**:
```bash
# Remove stale lock file
rm -f .terraform.tfstate.lock.info

# Or force unlock (use carefully)
terraform force-unlock LOCK_ID
```

---

### 10. Variable and Tag Management

#### Update ManagedBy Tag:
```hcl
# In locals.tf
locals {
  common_tags = merge(var.common_tags, {
    ManagedBy = "Your-Name"  # Change this value
  })
}
```

---

## Diagnostic Commands Reference

### Infrastructure Status:
```bash
# Terraform outputs
terraform output

# Check all resources
terraform state list

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file="environments/dev.tfvars"
```

### AWS Resource Checks:
```bash
# VPC information
aws ec2 describe-vpcs --vpc-ids vpc-xxx

# Security groups
aws ec2 describe-security-groups --group-ids sg-xxx

# Instance details
aws ec2 describe-instances --instance-ids i-xxx

# Load balancer status
aws elbv2 describe-load-balancers

# S3 bucket contents
aws s3 ls s3://bucket-name/html-web-app/
```

### Network Troubleshooting:
```bash
# From instance (via SSM)
ip route                    # Check routing table
ping target-ip             # Test connectivity
telnet target-ip port      # Test specific port
curl http://target         # Test HTTP
nslookup domain            # DNS resolution
```

---

## Best Practices Learned

1. **Always import existing resources** before creating new ones
2. **Use Session Manager** instead of SSH for private instance access
3. **Implement proper lifecycle rules** for resources that might already exist
4. **Use CIDR blocks** instead of security group references for cross-VPC rules
5. **Test both locally and via load balancer** for web applications
6. **Use targeted terraform apply** for specific resource updates
7. **Automate file uploads** using Terraform modules instead of manual commands
8. **Implement proper error handling** in Terraform configurations

---

## Quick Recovery Commands

### Complete Infrastructure Refresh:
```bash
# Destroy and recreate (use carefully)
terraform destroy -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Partial Updates:
```bash
# Update specific modules
terraform apply -target=module.asg -var-file="environments/dev.tfvars"
terraform apply -target=module.s3_upload -var-file="environments/dev.tfvars"
```

### Emergency Access:
```bash
# Direct access to private instances
aws ssm start-session --target i-instance-id

# Check load balancer health
aws elbv2 describe-target-health --target-group-arn arn:aws:...
```

---

## Success Indicators

✅ **Infrastructure Working When:**
- `terraform apply` completes without errors
- Load balancer returns HTTP 200 with web content
- Auto Scaling Group shows healthy instances
- Session Manager can connect to private instances
- S3 bucket contains uploaded web files
- CloudWatch logs show no critical errors

✅ **Web Application Working When:**
- `curl http://load-balancer-dns` returns HTML content
- Browser shows the web application
- Target group health checks pass
- Apache service is active on private instances

---

*This guide covers all major issues encountered during the DevOps Project 02 implementation and their proven solutions.*