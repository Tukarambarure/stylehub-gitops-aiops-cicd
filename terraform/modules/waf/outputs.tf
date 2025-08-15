output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_name" {
  description = "The name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.name
}

output "blocked_ips_id" {
  description = "The ID of the blocked IPs IP set"
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].id : null
}

output "blocked_ips_arn" {
  description = "The ARN of the blocked IPs IP set"
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].arn : null
}

output "waf_log_group_name" {
  description = "The name of the WAF CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf.name
}

output "waf_log_group_arn" {
  description = "The ARN of the WAF CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf.arn
}

output "waf_logging_role_arn" {
  description = "The ARN of the IAM role for WAF logging"
  value       = length(aws_iam_role.waf_logging) > 0 ? aws_iam_role.waf_logging[0].arn : null
}

output "waf_logging_role_name" {
  description = "The name of the IAM role for WAF logging"
  value       = length(aws_iam_role.waf_logging) > 0 ? aws_iam_role.waf_logging[0].name : null
}
