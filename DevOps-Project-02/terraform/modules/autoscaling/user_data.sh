#!/bin/bash
apt update -y
apt install -y apache2 awscli

# Add SSH public key for bastion access (if provided)
if [ -n '${ssh_public_key}' ]; then
    echo '${ssh_public_key}' >> /home/ubuntu/.ssh/authorized_keys
    chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
    chmod 600 /home/ubuntu/.ssh/authorized_keys
fi

# Start and enable apache2 service
systemctl start apache2
systemctl enable apache2

# Download application code from S3
aws s3 sync s3://${s3_bucket_name}/html-web-app/ /var/www/html/

# Set proper permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Restart apache2 to ensure everything is working
systemctl restart apache2