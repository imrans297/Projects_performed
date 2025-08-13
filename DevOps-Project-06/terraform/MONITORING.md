# Monitoring and Alerting Guide

## 📊 Overview

The CI/CD pipeline infrastructure includes comprehensive monitoring and alerting capabilities using AWS CloudWatch, SNS, and EventBridge.

## 🔍 Monitoring Components

### CloudWatch Metrics
- **EC2 Instance Metrics**: CPU, Memory, Disk utilization
- **Custom Jenkins Metrics**: Queue length, build failures, success rates
- **System Health Metrics**: Status checks, network performance

### CloudWatch Logs
- **Jenkins Master Logs**: `/aws/ec2/jenkins-master`
- **Jenkins Agent Logs**: `/aws/ec2/jenkins-agents`
- **Ansible Controller Logs**: `/aws/ec2/ansible-controller`
- **System Logs**: Syslog from all instances

### CloudWatch Alarms
- **High CPU Utilization** (>80% for 10 minutes)
- **High Memory Usage** (>85% for 10 minutes)
- **High Disk Usage** (>80% for 10 minutes)
- **Instance Status Check Failures**
- **Jenkins Queue Length** (>10 jobs)
- **Jenkins Build Failures** (>5 failures in 15 minutes)

## 🚨 Alerting Configuration

### SNS Topics
- **Primary Alert Topic**: Sends notifications to configured email addresses
- **Email Subscriptions**: Automatically configured based on `alert_email_addresses` variable

### Alert Channels
- **Email Notifications**: Immediate alerts for critical issues
- **EventBridge Rules**: EC2 state change notifications
- **Composite Alarms**: Overall system health monitoring

## 📈 Dashboard

### CloudWatch Dashboard Features
- **Real-time Metrics**: CPU, Memory, Disk usage across all instances
- **Jenkins Metrics**: Build queue, success/failure rates
- **Log Insights**: Error analysis and troubleshooting
- **System Overview**: Comprehensive infrastructure health view

### Dashboard Access
After deployment, access your dashboard at:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=dev-cicd-pipeline-cicd-pipeline
```

## 🔧 Configuration

### Environment Variables

#### Development Environment
```hcl
# environments/dev.tfvars
alert_email_addresses = ["devops-team@company.com", "admin@company.com"]
log_retention_days    = 14
```

#### Production Environment
```hcl
# environments/prod.tfvars
alert_email_addresses = ["devops-alerts@company.com", "sre-team@company.com", "oncall@company.com"]
log_retention_days    = 30
```

### Custom Metrics

#### Jenkins Metrics
The monitoring system tracks custom Jenkins metrics:
- `jenkins.queue.size`: Number of jobs in build queue
- `jenkins.builds.failed`: Failed build count
- `jenkins.builds.success`: Successful build count

#### System Metrics
- CPU utilization per instance
- Memory usage percentage
- Disk space utilization
- Network I/O statistics

## 📋 Alert Thresholds

### Critical Alerts (Immediate Action Required)
- **Instance Status Check Failed**: Instance is unhealthy
- **CPU > 90%** for 5 minutes: Performance degradation
- **Memory > 95%** for 5 minutes: Risk of OOM
- **Disk > 95%**: Storage full

### Warning Alerts (Monitor Closely)
- **CPU > 80%** for 10 minutes: High load
- **Memory > 85%** for 10 minutes: Memory pressure
- **Disk > 80%**: Storage getting full
- **Jenkins Queue > 10**: Build backlog

### Informational Alerts
- **Instance State Changes**: Start/stop/terminate events
- **Build Failures > 5**: Quality issues
- **Long Build Times**: Performance monitoring

## 🔍 Log Analysis

### CloudWatch Insights Queries

#### Jenkins Error Analysis
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

#### Build Failure Analysis
```sql
fields @timestamp, @message
| filter @message like /BUILD FAILED/ or @message like /FAILURE/
| sort @timestamp desc
| limit 50
```

#### System Performance Analysis
```sql
fields @timestamp, @message
| filter @message like /OutOfMemoryError/ or @message like /DiskFull/
| sort @timestamp desc
| limit 20
```

### Log Retention
- **Development**: 14 days
- **Production**: 30 days
- **Automatic Archival**: Logs moved to S3 after retention period

## 🛠️ Troubleshooting

### Common Issues

#### High CPU Usage
1. Check CloudWatch dashboard for affected instances
2. SSH to instance and run `htop` to identify processes
3. Review Jenkins build queue for resource-intensive jobs
4. Consider scaling up instance types or adding more agents

#### Memory Issues
1. Monitor memory usage trends in CloudWatch
2. Check for memory leaks in Jenkins jobs
3. Restart Jenkins service if necessary
4. Increase instance memory or optimize builds

#### Disk Space Issues
1. Check disk usage with `df -h`
2. Clean up old build artifacts
3. Configure Jenkins to clean workspace after builds
4. Increase EBS volume size if needed

#### Jenkins Queue Backup
1. Check agent connectivity in Jenkins UI
2. Verify agents are online and have capacity
3. Review build configurations for bottlenecks
4. Add more agents if needed

### Monitoring Health Checks

#### Daily Checks
- Review CloudWatch dashboard
- Check for any active alarms
- Verify all instances are healthy
- Monitor build success rates

#### Weekly Checks
- Analyze log patterns and trends
- Review alert frequency and accuracy
- Update alert thresholds if needed
- Check disk usage trends

#### Monthly Checks
- Review monitoring costs
- Optimize log retention policies
- Update alert contact lists
- Performance trend analysis

## 📞 Incident Response

### Alert Response Workflow
1. **Receive Alert**: Email notification with details
2. **Assess Severity**: Check dashboard for context
3. **Initial Response**: SSH to affected instance
4. **Investigate**: Use CloudWatch Logs and metrics
5. **Resolve**: Apply fix and monitor recovery
6. **Document**: Update runbooks and procedures

### Escalation Matrix
- **Level 1**: DevOps team member
- **Level 2**: Senior DevOps engineer
- **Level 3**: Infrastructure architect
- **Level 4**: Engineering manager

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Review and tune alert thresholds
- **Monthly**: Analyze monitoring costs and optimize
- **Quarterly**: Update monitoring strategy and tools

### Monitoring the Monitoring
- Set up alerts for CloudWatch agent failures
- Monitor SNS topic delivery failures
- Regular testing of alert mechanisms
- Backup monitoring configurations

## 📊 Metrics and KPIs

### Infrastructure KPIs
- **Uptime**: Target 99.9%
- **Response Time**: Alert response < 5 minutes
- **MTTR**: Mean time to recovery < 30 minutes
- **False Positive Rate**: < 5%

### CI/CD KPIs
- **Build Success Rate**: > 95%
- **Build Time**: Trend analysis
- **Queue Wait Time**: < 5 minutes average
- **Deployment Frequency**: Track and improve

## 🔐 Security Monitoring

### Security Alerts
- Failed SSH attempts
- Unusual network activity
- Privilege escalation attempts
- Unauthorized access patterns

### Compliance Monitoring
- Log integrity checks
- Access audit trails
- Configuration drift detection
- Security patch compliance

---

## 📚 Additional Resources

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Jenkins Monitoring Best Practices](https://www.jenkins.io/doc/book/system-administration/monitoring/)
- [Infrastructure Monitoring Guide](https://aws.amazon.com/architecture/well-architected/)

## 🆘 Support Contacts

- **DevOps Team**: devops-team@company.com
- **On-Call Engineer**: oncall@company.com
- **Emergency Escalation**: +1-XXX-XXX-XXXX