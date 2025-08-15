# StyleHub AWS Infrastructure with Terraform

This directory contains the Terraform configuration for deploying the complete AWS infrastructure for the StyleHub e-commerce application on AWS EKS.

## Architecture Overview

The infrastructure includes:

- **VPC** with public, private, and database subnets across multiple AZs
- **EKS Cluster** with managed node groups and essential add-ons
- **RDS PostgreSQL** database (optional)
- **ElastiCache Redis** cluster (optional)
- **Application Load Balancer** with access logging
- **CloudWatch** monitoring, logging, and alerting
- **WAF v2** for web application firewall protection (optional)

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **AWS S3 bucket** for Terraform state (create manually)
5. **AWS DynamoDB table** for state locking (create manually)

## Quick Start

### 1. Create S3 Backend Resources

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://stylehub-terraform-state --region us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket stylehub-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name stylehub-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-west-2
```

### 2. Configure Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Required variables
db_password = "your-secure-database-password"
redis_auth_token = "your-redis-auth-token"

# Optional: Enable production features
enable_rds = true
enable_elasticache = true
enable_waf = true
enable_email_alerts = true
alert_email = "your-email@domain.com"
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name stylehub-cluster

# Verify cluster access
kubectl get nodes
```

## Module Structure

```
terraform/
├── main.tf                 # Root configuration
├── variables.tf            # Input variables
├── locals.tf              # Local values
├── terraform.tfvars       # Variable values
├── outputs.tf             # Output values
├── README.md              # This file
└── modules/
    ├── vpc/               # VPC and networking
    ├── eks/               # EKS cluster and add-ons
    ├── rds/               # RDS PostgreSQL
    ├── elasticache/       # ElastiCache Redis
    ├── alb/               # Application Load Balancer
    ├── cloudwatch/        # Monitoring and alerting
    └── waf/               # Web Application Firewall
```

## Configuration Options

### VPC Configuration

- **CIDR Block**: 10.0.0.0/16
- **Availability Zones**: 3 AZs
- **Subnets**: Public, Private, and Database subnets
- **NAT Gateways**: One per AZ for private subnet internet access

### EKS Configuration

- **Kubernetes Version**: 1.28
- **Node Groups**: Managed node groups with auto-scaling
- **Add-ons**: 
  - AWS Load Balancer Controller
  - EBS CSI Driver
  - Cluster Autoscaler
  - Node Termination Handler

### Security Features

- **IAM Roles for Service Accounts (IRSA)**: Secure pod-to-AWS-service communication
- **Security Groups**: Restrictive access rules
- **Encryption**: At-rest and in-transit encryption
- **WAF**: Web application firewall with rate limiting and geo-blocking

### Monitoring and Alerting

- **CloudWatch Dashboard**: Centralized monitoring view
- **Log Groups**: Application, EKS, ALB, and WAF logs
- **Alarms**: CPU, memory, error rates, and custom metrics
- **SNS Notifications**: Email alerts for critical issues

## Environment-Specific Deployments

### Development Environment

```hcl
# terraform.tfvars.dev
environment = "development"
enable_rds = false
enable_elasticache = false
enable_waf = false
enable_email_alerts = false

eks_managed_node_groups = {
  general = {
    name = "general"
    instance_types = ["t3.small"]
    capacity_type = "ON_DEMAND"
    min_size = 1
    max_size = 3
    desired_size = 1
    disk_size = 20
    labels = {
      "node.kubernetes.io/role" = "general"
    }
    taints = []
  }
}
```

### Production Environment

```hcl
# terraform.tfvars.prod
environment = "production"
enable_rds = true
enable_elasticache = true
enable_waf = true
enable_email_alerts = true
alert_email = "ops@yourcompany.com"

eks_managed_node_groups = {
  general = {
    name = "general"
    instance_types = ["t3.medium", "t3.large"]
    capacity_type = "ON_DEMAND"
    min_size = 2
    max_size = 10
    desired_size = 3
    disk_size = 50
    labels = {
      "node.kubernetes.io/role" = "general"
    }
    taints = []
  }
  spot = {
    name = "spot"
    instance_types = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
    capacity_type = "SPOT"
    min_size = 1
    max_size = 5
    desired_size = 2
    disk_size = 50
    labels = {
      "node.kubernetes.io/role" = "spot"
    }
    taints = []
  }
}
```

## Deployment Commands

### Development

```bash
terraform workspace new dev
terraform workspace select dev
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

### Production

```bash
terraform workspace new prod
terraform workspace select prod
terraform plan -var-file="terraform.tfvars.prod"
terraform apply -var-file="terraform.tfvars.prod"
```

## Post-Deployment Steps

1. **Deploy Application**: Use the provided Kubernetes manifests and CI/CD pipelines
2. **Configure DNS**: Point your domain to the ALB DNS name
3. **SSL Certificate**: Configure SSL/TLS termination at the ALB
4. **Monitoring**: Set up additional monitoring tools if needed
5. **Backup Strategy**: Configure automated backups for RDS and EBS volumes

## Security Best Practices

1. **Network Security**:
   - Use private subnets for application workloads
   - Restrict database access to private subnets only
   - Implement security groups with minimal required access

2. **Access Control**:
   - Use IAM roles for service accounts
   - Implement least privilege access
   - Enable CloudTrail for audit logging

3. **Data Protection**:
   - Enable encryption at rest and in transit
   - Use AWS KMS for key management
   - Implement proper backup and recovery procedures

4. **Monitoring and Alerting**:
   - Set up comprehensive CloudWatch monitoring
   - Configure alerts for security events
   - Monitor WAF logs for potential threats

## Troubleshooting

### Common Issues

1. **Terraform State Lock**: If you encounter state lock issues, check the DynamoDB table
2. **EKS Node Issues**: Verify node group IAM roles and security groups
3. **ALB Health Checks**: Check target group health and security group rules
4. **RDS Connectivity**: Verify subnet groups and security group rules

### Useful Commands

```bash
# Check EKS cluster status
aws eks describe-cluster --name stylehub-cluster --region us-west-2

# View node group status
aws eks describe-nodegroup --cluster-name stylehub-cluster --nodegroup-name general --region us-west-2

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/stylehub-production"
```

## Cost Optimization

1. **Use Spot Instances**: Configure spot node groups for non-critical workloads
2. **Right-size Resources**: Monitor and adjust instance types based on usage
3. **Scheduled Scaling**: Use cluster autoscaler to scale down during off-hours
4. **Reserved Instances**: Purchase RIs for predictable workloads
5. **Storage Optimization**: Use appropriate storage classes and lifecycle policies

## Maintenance

### Regular Tasks

1. **Terraform Updates**: Keep Terraform and provider versions updated
2. **EKS Updates**: Plan and execute EKS version upgrades
3. **Security Patches**: Apply security updates to node groups
4. **Backup Verification**: Test backup and recovery procedures
5. **Cost Review**: Monitor and optimize costs monthly

### Update Procedures

```bash
# Update Terraform providers
terraform init -upgrade

# Plan updates
terraform plan

# Apply updates during maintenance window
terraform apply
```

## Support

For issues and questions:

1. Check the [AWS EKS documentation](https://docs.aws.amazon.com/eks/)
2. Review [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
3. Consult the [Kubernetes documentation](https://kubernetes.io/docs/)

## License

This infrastructure code is provided as-is for educational and development purposes.
