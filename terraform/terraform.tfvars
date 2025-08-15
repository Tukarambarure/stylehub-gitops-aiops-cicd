# General Configuration
project_name = "stylehub"
environment  = "production"
owner        = "devops-team"
aws_region   = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
enable_nat_gateway = true

# EKS Configuration
cluster_name = "stylehub-cluster"
cluster_version = "1.28"
cluster_endpoint_public_access = true

# EKS Node Groups
eks_managed_node_groups = {
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

# Database Configuration (set to true for production)
enable_rds = false
db_name = "stylehub"
db_username = "postgres"
db_password = "your-secure-password-here"

# ElastiCache Configuration (set to true for production)
enable_elasticache = false
redis_auth_token = "your-redis-auth-token-here"

# ALB Configuration
enable_alb_deletion_protection = true
enable_alb_access_logs = true

# CloudWatch Configuration
enable_email_alerts = false
alert_email = "alerts@yourcompany.com"

# WAF Configuration (set to true for production)
enable_waf = false
waf_rate_limit = 2000
waf_blocked_ip_addresses = []
waf_blocked_country_codes = []
waf_enable_logging = true
waf_enable_monitoring = true
