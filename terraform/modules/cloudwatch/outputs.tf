output "application_log_group_name" {
  description = "The name of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "The ARN of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.arn
}

output "eks_log_group_name" {
  description = "The name of the EKS CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks.name
}

output "eks_log_group_arn" {
  description = "The ARN of the EKS CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks.arn
}

output "alb_log_group_name" {
  description = "The name of the ALB CloudWatch log group"
  value       = aws_cloudwatch_log_group.alb.name
}

output "alb_log_group_arn" {
  description = "The ARN of the ALB CloudWatch log group"
  value       = aws_cloudwatch_log_group.alb.arn
}

output "dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "The ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "sns_topic_name" {
  description = "The name of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.name
}

output "cloudwatch_logs_role_arn" {
  description = "The ARN of the IAM role for CloudWatch logs"
  value       = aws_iam_role.cloudwatch_logs.arn
}

output "cloudwatch_logs_role_name" {
  description = "The name of the IAM role for CloudWatch logs"
  value       = aws_iam_role.cloudwatch_logs.name
}
