# Outputs for Monitoring Module

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.name
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cicd_pipeline.dashboard_name}"
}

output "log_groups" {
  description = "CloudWatch log groups created"
  value = {
    jenkins_master      = aws_cloudwatch_log_group.jenkins_master.name
    jenkins_agents      = aws_cloudwatch_log_group.jenkins_agents.name
    ansible_controller  = aws_cloudwatch_log_group.ansible_controller.name
  }
}

output "alarms_created" {
  description = "List of CloudWatch alarms created"
  value = {
    jenkins_master_cpu    = aws_cloudwatch_metric_alarm.jenkins_master_cpu.alarm_name
    jenkins_master_memory = aws_cloudwatch_metric_alarm.jenkins_master_memory.alarm_name
    jenkins_master_disk   = aws_cloudwatch_metric_alarm.jenkins_master_disk.alarm_name
    jenkins_master_status = aws_cloudwatch_metric_alarm.jenkins_master_status.alarm_name
    ansible_controller_cpu = aws_cloudwatch_metric_alarm.ansible_controller_cpu.alarm_name
    jenkins_queue_length  = aws_cloudwatch_metric_alarm.jenkins_queue_length.alarm_name
    jenkins_failed_builds = aws_cloudwatch_metric_alarm.jenkins_failed_builds.alarm_name
    system_health        = aws_cloudwatch_composite_alarm.system_health.alarm_name
  }
}

output "cloudwatch_agent_config_parameter" {
  description = "SSM parameter name for CloudWatch agent configuration"
  value       = aws_ssm_parameter.cloudwatch_agent_config.name
}