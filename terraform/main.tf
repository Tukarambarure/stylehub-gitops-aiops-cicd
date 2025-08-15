terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
  backend "s3" {
    bucket         = "stylehub-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "stylehub-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  azs              = data.aws_availability_zones.available.names
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  enable_nat_gateway = var.enable_nat_gateway
  tags             = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name                    = var.project_name
  environment                     = var.environment
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  eks_managed_node_groups         = var.eks_managed_node_groups
  tags                            = local.common_tags
}

# RDS Module (conditional)
module "rds" {
  count = var.enable_rds ? 1 : 0
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnets
  db_name      = var.db_name
  db_username  = var.db_username
  db_password  = var.db_password
  tags         = local.common_tags
}

# ElastiCache Module (conditional)
module "elasticache" {
  count = var.enable_elasticache ? 1 : 0
  source = "./modules/elasticache"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  eks_security_group_id  = module.eks.cluster_security_group_id
  auth_token             = var.redis_auth_token
  alarm_actions          = [module.cloudwatch.sns_topic_arn]
  tags                   = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name              = var.project_name
  environment               = var.environment
  subnet_ids                = module.vpc.public_subnets
  vpc_id                    = module.vpc.vpc_id
  enable_deletion_protection = var.enable_alb_deletion_protection
  enable_access_logs        = var.enable_alb_access_logs
  tags                      = local.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  alb_arn_suffix            = module.alb.alb_arn_suffix
  eks_cluster_name          = var.cluster_name
  rds_instance_id           = var.enable_rds ? module.rds[0].db_instance_id : ""
  elasticache_cluster_id    = var.enable_elasticache ? module.elasticache[0].replication_group_id : ""
  enable_email_alerts       = var.enable_email_alerts
  alert_email               = var.alert_email
  alarm_actions             = [module.cloudwatch.sns_topic_arn]
  tags                      = local.common_tags
}

# WAF Module (conditional)
module "waf" {
  count = var.enable_waf ? 1 : 0
  source = "./modules/waf"

  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  alb_arn                = module.alb.alb_arn
  rate_limit             = var.waf_rate_limit
  blocked_ip_addresses   = var.waf_blocked_ip_addresses
  blocked_country_codes  = var.waf_blocked_country_codes
  enable_logging         = var.waf_enable_logging
  enable_monitoring      = var.waf_enable_monitoring
  alarm_actions          = [module.cloudwatch.sns_topic_arn]
  tags                   = local.common_tags
}

# Outputs
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

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnets
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = var.enable_rds ? module.rds[0].db_instance_endpoint : null
}

output "elasticache_endpoint" {
  description = "ElastiCache endpoint"
  value       = var.enable_elasticache ? module.elasticache[0].primary_endpoint_address : null
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.cloudwatch.sns_topic_arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? module.waf[0].web_acl_arn : null
}
