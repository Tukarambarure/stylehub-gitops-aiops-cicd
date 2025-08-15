# StyleHub Deployment Guide

This guide provides comprehensive instructions for deploying the StyleHub e-commerce application on AWS EKS with a complete CI/CD pipeline and infrastructure as code.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Setup with Terraform](#infrastructure-setup-with-terraform)
4. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
5. [Application Deployment](#application-deployment)
6. [Monitoring and Observability](#monitoring-and-observability)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting](#troubleshooting)

## Architecture Overview

The StyleHub application is deployed as a microservices architecture on AWS EKS with the following components:

### Infrastructure Components
- **AWS EKS Cluster**: Kubernetes cluster for container orchestration
- **VPC**: Multi-AZ networking with public, private, and database subnets
- **RDS PostgreSQL**: Managed database service (optional)
- **ElastiCache Redis**: Managed caching service (optional)
- **Application Load Balancer**: Traffic distribution and SSL termination
- **CloudWatch**: Monitoring, logging, and alerting
- **WAF v2**: Web application firewall protection (optional)

### Application Components
- **Frontend UI**: React/TypeScript application
- **Product Service**: Product catalog and management
- **User Service**: User authentication and management
- **Cart Service**: Shopping cart functionality
- **Order Service**: Order processing and management

### CI/CD Pipeline
- **Separate Pipelines**: Individual pipelines for frontend and each backend service
- **Reusable Workflows**: Shared backend service workflow for consistency
- **Infrastructure Pipeline**: Dedicated pipeline for core infrastructure
- **Path-based Triggers**: Efficient pipeline execution based on code changes

## Prerequisites

### Required Tools
- **AWS CLI** >= 2.0
- **Terraform** >= 1.0
- **kubectl** >= 1.28
- **Docker** >= 20.0
- **Git** >= 2.0

### AWS Account Setup
- AWS account with appropriate permissions
- IAM user/role with EKS, EC2, RDS, ElastiCache, and other service permissions
- S3 bucket for Terraform state (will be created)
- DynamoDB table for Terraform state locking (will be created)

### GitHub Repository Setup
- GitHub repository with the application code
- GitHub Actions enabled
- Required secrets configured (see CI/CD section)

## Infrastructure Setup with Terraform

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

### 2. Configure Terraform Variables

Edit `terraform/terraform.tfvars` with your specific values:

```hcl
# General Configuration
project_name = "stylehub"
environment  = "production"
owner        = "devops-team"
aws_region   = "us-west-2"

# Database Configuration (set to true for production)
enable_rds = true
db_password = "your-secure-database-password"

# ElastiCache Configuration (set to true for production)
enable_elasticache = true
redis_auth_token = "your-redis-auth-token"

# WAF Configuration (set to true for production)
enable_waf = true

# CloudWatch Configuration
enable_email_alerts = true
alert_email = "alerts@yourcompany.com"
```

### 3. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

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

## CI/CD Pipeline Setup

### GitHub Secrets Configuration

Configure the following secrets in your GitHub repository:

```bash
# Docker Hub credentials
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password

# AWS credentials for EKS deployment
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-west-2

# EKS cluster configuration
EKS_CLUSTER_NAME=stylehub-cluster

# Optional: SonarQube token for code quality
SONAR_TOKEN=your-sonarqube-token
```

### Pipeline Structure

The CI/CD pipeline is organized into separate workflows for better scalability and efficiency:

1. **Frontend Pipeline** (`.github/workflows/frontend-ci-cd.yml`)
   - Triggered by changes in frontend code
   - Code quality checks with ESLint and TypeScript
   - Security scanning with Trivy
   - Build and test Docker image
   - Deploy to EKS

2. **Backend Service Pipelines** (`.github/workflows/{service}-ci-cd.yml`)
   - Individual pipelines for each microservice
   - Use reusable workflow for consistency
   - Path-based triggers for efficiency
   - Code quality, security, build, and deployment

3. **Infrastructure Pipeline** (`.github/workflows/infrastructure-deploy.yml`)
   - Deploys core Kubernetes infrastructure
   - Security scanning of Kubernetes manifests
   - Direct deployment to EKS

4. **Reusable Backend Workflow** (`.github/workflows/backend-service-ci-cd.yml`)
   - Shared workflow for backend services
   - Consistent CI/CD process across services
   - Configurable parameters for each service

### Pipeline Features

- **Code Quality**: ESLint, TypeScript, Flake8, Black, Isort, Mypy, Bandit
- **Security Scanning**: Trivy vulnerability scanning
- **Testing**: Unit tests with Vitest and Pytest
- **Container Security**: Multi-stage builds, non-root users
- **Efficient Triggers**: Path-based pipeline execution
- **Scalable Architecture**: Separate pipelines for each service

## Application Deployment

### 1. Deploy Core Infrastructure

```bash
# Deploy namespace, configmaps, secrets, and monitoring
kubectl apply -k kubernetes/
```

### 2. Deploy Application Services

The application will be automatically deployed through the CI/CD pipelines when code is pushed to the main branch.

Alternatively, deploy manually:

```bash
# Deploy all services
kubectl apply -f kubernetes/ui/
kubectl apply -f kubernetes/product-service/
kubectl apply -f kubernetes/user-service/
kubectl apply -f kubernetes/cart-service/
kubectl apply -f kubernetes/order-service/
```

### 3. Verify Deployment

```bash
# Check all pods
kubectl get pods -n stylehub

# Check services
kubectl get svc -n stylehub

# Check ingress
kubectl get ingress -n stylehub

# Check HPA
kubectl get hpa -n stylehub
```

### 4. Access the Application

```bash
# Get the ALB DNS name
kubectl get svc stylehub-ui-loadbalancer -n stylehub -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or use the ALB DNS name from Terraform output
terraform output alb_dns_name
```

## Monitoring and Observability

### CloudWatch Dashboard

Access the CloudWatch dashboard to monitor:
- ALB metrics (request count, response time, error rates)
- EKS cluster metrics (node count, failed nodes)
- RDS metrics (CPU, connections, I/O)
- ElastiCache metrics (CPU, memory, connections)

### Logs

Application logs are available in CloudWatch:
- Application logs: `/aws/application/stylehub-production`
- EKS logs: `/aws/eks/stylehub-production/cluster`
- ALB logs: `/aws/applicationloadbalancer/stylehub-production`
- WAF logs: `/aws/wafv2/stylehub-production`

### Alerts

Configured CloudWatch alarms for:
- High CPU/memory utilization
- Error rate thresholds
- Failed health checks
- Security events

## Security Considerations

### Network Security
- Private subnets for application workloads
- Database access restricted to private subnets
- Security groups with minimal required access
- WAF protection for web traffic

### Access Control
- IAM roles for service accounts (IRSA)
- Least privilege access principles
- CloudTrail audit logging
- Encrypted communication

### Data Protection
- Encryption at rest and in transit
- AWS KMS for key management
- Regular backup procedures
- Secure secret management

## Troubleshooting

### Common Issues

1. **EKS Node Issues**
   ```bash
   # Check node status
   kubectl get nodes
   kubectl describe node <node-name>
   
   # Check node group status
   aws eks describe-nodegroup --cluster-name stylehub-cluster --nodegroup-name general
   ```

2. **Pod Issues**
   ```bash
   # Check pod status
   kubectl get pods -n stylehub
   kubectl describe pod <pod-name> -n stylehub
   kubectl logs <pod-name> -n stylehub
   ```

3. **Service Issues**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n stylehub
   kubectl describe svc <service-name> -n stylehub
   ```

4. **ALB Issues**
   ```bash
   # Check target health
   aws elbv2 describe-target-health --target-group-arn <target-group-arn>
   
   # Check ALB logs
   aws logs filter-log-events --log-group-name "/aws/applicationloadbalancer/stylehub-production"
   ```

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Check events
kubectl get events -n stylehub --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n stylehub
kubectl top nodes

# Check HPA status
kubectl describe hpa -n stylehub

# Check ingress status
kubectl describe ingress -n stylehub
```

### Log Analysis

```bash
# View application logs
kubectl logs -f deployment/stylehub-ui -n stylehub

# View service logs
kubectl logs -f deployment/stylehub-product-service -n stylehub

# Check CloudWatch logs
aws logs filter-log-events --log-group-name "/aws/application/stylehub-production"
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
# Update Terraform infrastructure
cd terraform
terraform plan
terraform apply

# Update application
git push origin main  # Triggers CI/CD pipelines

# Update Kubernetes manifests
kubectl apply -k kubernetes/
```

## Support

For issues and questions:

1. Check the [AWS EKS documentation](https://docs.aws.amazon.com/eks/)
2. Review [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
3. Consult the [Kubernetes documentation](https://kubernetes.io/docs/)
4. Review the [GitHub Actions documentation](https://docs.github.com/en/actions)

## License

This deployment guide and associated code is provided as-is for educational and development purposes.
