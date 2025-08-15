# General Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "stylehub"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

# EKS Variables
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "stylehub-cluster"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "eks_managed_node_groups" {
  description = "EKS managed node groups configuration"
  type = map(object({
    name = string
    instance_types = list(string)
    capacity_type = string
    min_size = number
    max_size = number
    desired_size = number
    disk_size = number
    labels = map(string)
    taints = list(object({
      key = string
      value = string
      effect = string
    }))
  }))
  default = {
    general = {
      name = "general"
      instance_types = ["t3.medium"]
      capacity_type = "ON_DEMAND"
      min_size = 1
      max_size = 5
      desired_size = 2
      disk_size = 20
      labels = {
        "node.kubernetes.io/role" = "general"
      }
      taints = []
    }
  }
}

# RDS Variables
variable "enable_rds" {
  description = "Enable RDS instance"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "stylehub"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# ElastiCache Variables
variable "enable_elasticache" {
  description = "Enable ElastiCache instance"
  type        = bool
  default     = false
}

variable "redis_auth_token" {
  description = "Redis auth token"
  type        = string
  sensitive   = true
  default     = null
}

# ALB Variables
variable "enable_alb_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = true
}

# CloudWatch Variables
variable "enable_email_alerts" {
  description = "Enable email alerts"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

# WAF Variables
variable "enable_waf" {
  description = "Enable WAF"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate limit"
  type        = number
  default     = 2000
}

variable "waf_blocked_ip_addresses" {
  description = "IP addresses to block in WAF"
  type        = list(string)
  default     = []
}

variable "waf_blocked_country_codes" {
  description = "Country codes to block in WAF"
  type        = list(string)
  default     = []
}

variable "waf_enable_logging" {
  description = "Enable WAF logging"
  type        = bool
  default     = true
}

variable "waf_enable_monitoring" {
  description = "Enable WAF monitoring"
  type        = bool
  default     = true
}
