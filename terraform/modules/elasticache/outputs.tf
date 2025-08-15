output "replication_group_id" {
  description = "The ID of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.main.id
}

output "replication_group_arn" {
  description = "The ARN of the ElastiCache Replication Group"
  value       = aws_elasticache_replication_group.main.arn
}

output "primary_endpoint_address" {
  description = "The address of the endpoint for the primary node in the replication group"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "The address of the endpoint for the reader node in the replication group"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "port" {
  description = "The port number on which each of the nodes accepts connections"
  value       = aws_elasticache_replication_group.main.port
}

output "member_clusters" {
  description = "The identifiers of all the nodes that are part of this replication group"
  value       = aws_elasticache_replication_group.main.member_clusters
}

output "subnet_group_id" {
  description = "The ID of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.main.id
}

output "subnet_group_arn" {
  description = "The ARN of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.main.arn
}

output "parameter_group_id" {
  description = "The ID of the ElastiCache parameter group"
  value       = aws_elasticache_parameter_group.main.id
}

output "parameter_group_arn" {
  description = "The ARN of the ElastiCache parameter group"
  value       = aws_elasticache_parameter_group.main.arn
}

output "security_group_id" {
  description = "The ID of the ElastiCache security group"
  value       = aws_security_group.elasticache.id
}

output "security_group_arn" {
  description = "The ARN of the ElastiCache security group"
  value       = aws_security_group.elasticache.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for ElastiCache"
  value       = aws_cloudwatch_log_group.elasticache.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for ElastiCache"
  value       = aws_cloudwatch_log_group.elasticache.arn
}
