output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "cluster_iam_role_name" {
  description = "EKS cluster IAM role name"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "ebs_csi_irsa_role_arn" {
  description = "EBS CSI Driver IAM role ARN"
  value       = module.ebs_csi_irsa_role.iam_role_arn
}

output "aws_load_balancer_controller_irsa_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

output "cluster_autoscaler_irsa_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
}
