# Monitoring and Alerting Module for CI/CD Pipeline

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"

  tags = var.tags
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.alert_email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Log Groups for Applications
resource "aws_cloudwatch_log_group" "jenkins_master" {
  name              = "/aws/ec2/jenkins-master"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jenkins-master-logs"
  })
}

resource "aws_cloudwatch_log_group" "jenkins_agents" {
  name              = "/aws/ec2/jenkins-agents"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-jenkins-agents-logs"
  })
}

resource "aws_cloudwatch_log_group" "ansible_controller" {
  name              = "/aws/ec2/ansible-controller"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ansible-controller-logs"
  })
}

# CloudWatch Alarms for EC2 Instances

# Jenkins Master Alarms
resource "aws_cloudwatch_metric_alarm" "jenkins_master_cpu" {
  alarm_name          = "${var.name_prefix}-jenkins-master-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors jenkins master cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.jenkins_master_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "jenkins_master_memory" {
  alarm_name          = "${var.name_prefix}-jenkins-master-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors jenkins master memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.jenkins_master_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "jenkins_master_disk" {
  alarm_name          = "${var.name_prefix}-jenkins-master-high-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors jenkins master disk utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.jenkins_master_instance_id
    MountPath  = "/"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "jenkins_master_status" {
  alarm_name          = "${var.name_prefix}-jenkins-master-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors jenkins master instance status"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.jenkins_master_instance_id
  }

  tags = var.tags
}

# Jenkins Agents Alarms
resource "aws_cloudwatch_metric_alarm" "jenkins_agents_cpu" {
  count = length(var.jenkins_agent_instance_ids)

  alarm_name          = "${var.name_prefix}-jenkins-agent-${count.index + 1}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors jenkins agent ${count.index + 1} cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.jenkins_agent_instance_ids[count.index]
  }

  tags = var.tags
}

# Ansible Controller Alarms
resource "aws_cloudwatch_metric_alarm" "ansible_controller_cpu" {
  alarm_name          = "${var.name_prefix}-ansible-controller-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ansible controller cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.ansible_controller_instance_id
  }

  tags = var.tags
}

# Custom Metrics for Jenkins
resource "aws_cloudwatch_metric_alarm" "jenkins_queue_length" {
  alarm_name          = "${var.name_prefix}-jenkins-queue-length"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "jenkins.queue.size"
  namespace           = "Jenkins"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors jenkins build queue length"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "jenkins_failed_builds" {
  alarm_name          = "${var.name_prefix}-jenkins-failed-builds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "jenkins.builds.failed"
  namespace           = "Jenkins"
  period              = "900"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors jenkins failed builds"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "cicd_pipeline" {
  dashboard_name = "${var.name_prefix}-cicd-pipeline"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.jenkins_master_instance_id],
            [".", ".", ".", var.ansible_controller_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CWAgent", "MemoryUtilization", "InstanceId", var.jenkins_master_instance_id],
            [".", ".", ".", var.ansible_controller_instance_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Memory Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CWAgent", "DiskSpaceUtilization", "InstanceId", var.jenkins_master_instance_id, "MountPath", "/"],
            [".", ".", ".", var.ansible_controller_instance_id, ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Disk Space Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Jenkins", "jenkins.queue.size"],
            [".", "jenkins.builds.failed"],
            [".", "jenkins.builds.success"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Jenkins Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/ec2/jenkins-master' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Jenkins Master Errors"
        }
      }
    ]
  })
}

# CloudWatch Composite Alarm for Overall System Health
resource "aws_cloudwatch_composite_alarm" "system_health" {
  alarm_name        = "${var.name_prefix}-system-health"
  alarm_description = "Composite alarm for overall CI/CD system health"

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.jenkins_master_cpu.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.jenkins_master_memory.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.jenkins_master_status.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.ansible_controller_cpu.alarm_name})"
  ])

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

# EventBridge Rules for EC2 State Changes
resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "${var.name_prefix}-ec2-state-change"
  description = "Capture EC2 instance state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["stopped", "stopping", "terminated", "terminating"]
      instance-id = concat(
        [var.jenkins_master_instance_id, var.ansible_controller_instance_id],
        var.jenkins_agent_instance_ids
      )
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}

# CloudWatch Insights Queries
resource "aws_cloudwatch_query_definition" "jenkins_errors" {
  name = "${var.name_prefix}-jenkins-errors"

  log_group_names = [
    aws_cloudwatch_log_group.jenkins_master.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "build_failures" {
  name = "${var.name_prefix}-build-failures"

  log_group_names = [
    aws_cloudwatch_log_group.jenkins_master.name,
    aws_cloudwatch_log_group.jenkins_agents.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /BUILD FAILED/ or @message like /FAILURE/
| sort @timestamp desc
| limit 50
EOF
}

# CloudWatch Agent Configuration for Custom Metrics
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name = "/${var.name_prefix}/cloudwatch-agent/config"
  type = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "cwagent"
    }
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        cpu = {
          measurement = [
            "cpu_usage_idle",
            "cpu_usage_iowait",
            "cpu_usage_user",
            "cpu_usage_system"
          ]
          metrics_collection_interval = 60
          totalcpu                    = false
        }
        disk = {
          measurement = [
            "used_percent"
          ]
          metrics_collection_interval = 60
          resources = [
            "*"
          ]
        }
        diskio = {
          measurement = [
            "io_time",
            "read_bytes",
            "write_bytes",
            "reads",
            "writes"
          ]
          metrics_collection_interval = 60
          resources = [
            "*"
          ]
        }
        mem = {
          measurement = [
            "mem_used_percent"
          ]
          metrics_collection_interval = 60
        }
        netstat = {
          measurement = [
            "tcp_established",
            "tcp_time_wait"
          ]
          metrics_collection_interval = 60
        }
        swap = {
          measurement = [
            "swap_used_percent"
          ]
          metrics_collection_interval = 60
        }
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path      = "/var/log/jenkins/jenkins.log"
              log_group_name = aws_cloudwatch_log_group.jenkins_master.name
              log_stream_name = "{instance_id}/jenkins.log"
              timezone       = "UTC"
            },
            {
              file_path      = "/var/log/syslog"
              log_group_name = "/aws/ec2/syslog"
              log_stream_name = "{instance_id}/syslog"
              timezone       = "UTC"
            }
          ]
        }
      }
    }
  })

  tags = var.tags
}