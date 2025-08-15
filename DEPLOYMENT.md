# StyleHub Kubernetes Deployment Guide

This guide provides comprehensive instructions for deploying the StyleHub e-commerce application on Kubernetes with CI/CD pipeline following DevOps best practices.

## Prerequisites

### 1. Kubernetes Cluster
- Kubernetes 1.24+ cluster
- Ingress controller (NGINX Ingress)
- Cert-manager for SSL certificates
- ArgoCD for GitOps deployment
- Prometheus and Grafana for monitoring

### 2. Tools and Services
- Docker Hub account
- GitHub repository
- SonarQube instance
- Slack webhook (optional)

### 3. Required Secrets
Set up the following GitHub repository secrets:

```bash
# Docker Hub credentials
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password

# SonarQube
SONAR_TOKEN=your-sonarqube-token
SONAR_HOST_URL=https://your-sonarqube-instance.com

# Kubernetes
KUBECONFIG=base64-encoded-kubeconfig

# ArgoCD
ARGOCD_SERVER=https://your-argocd-instance.com
ARGOCD_TOKEN=your-argocd-token

# Slack (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

## Infrastructure Setup

### 1. Install Ingress Controller
```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Install Cert-Manager
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
```

### 3. Install ArgoCD
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4. Install Prometheus and Grafana
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

## Application Deployment

### 1. Deploy Infrastructure Components
```bash
# Apply namespace and resource quotas
kubectl apply -f kubernetes/namespace.yaml

# Apply configmaps and secrets
kubectl apply -f kubernetes/configmaps.yaml
kubectl apply -f kubernetes/secrets.yaml

# Deploy database and cache
kubectl apply -f kubernetes/database.yaml
kubectl apply -f kubernetes/redis.yaml

# Deploy monitoring
kubectl apply -f kubernetes/monitoring.yaml

# Apply network policies
kubectl apply -f kubernetes/network-policy.yaml
```

### 2. Deploy Application Services
```bash
# Deploy all services using kustomize
kubectl apply -k kubernetes/

# Or deploy individually
kubectl apply -f kubernetes/ui/deployment.yaml
kubectl apply -f kubernetes/product-service/deployment.yaml
kubectl apply -f kubernetes/user-service/deployment.yaml
kubectl apply -f kubernetes/cart-service/deployment.yaml
kubectl apply -f kubernetes/order-service/deployment.yaml
```

### 3. Configure ArgoCD Application
```bash
# Update the repository URL in argocd/application.yaml
# Replace 'your-username' with your actual GitHub username

# Apply ArgoCD application
kubectl apply -f argocd/application.yaml
```

## CI/CD Pipeline Setup

### 1. Separate Service Pipelines
The application uses separate CI/CD pipelines for each service for better scalability and efficiency:

#### **Frontend Pipeline** (`.github/workflows/frontend-ci-cd.yml`)
- **Triggers**: Changes to `src/`, `public/`, `package.json`, `kubernetes/ui/`
- **Features**: 
  - ESLint, TypeScript checking, Prettier
  - SonarQube analysis
  - Security scanning with Trivy
  - Unit tests with coverage
  - Docker image building and scanning
  - Direct deployment to EKS

#### **Backend Service Pipelines**
Each backend service has its own pipeline:
- **Product Service** (`.github/workflows/product-service-ci-cd.yml`)
- **User Service** (`.github/workflows/user-service-ci-cd.yml`)
- **Cart Service** (`.github/workflows/cart-service-ci-cd.yml`)
- **Order Service** (`.github/workflows/order-service-ci-cd.yml`)

**Features**:
- Python linting (flake8, black, isort, mypy)
- Security scanning (Bandit, Trivy)
- Unit tests with coverage
- SonarQube analysis
- Docker image building and scanning
- Direct deployment to EKS

#### **Infrastructure Pipeline** (`.github/workflows/infrastructure-deploy.yml`)
- **Triggers**: Changes to infrastructure manifests
- **Features**:
  - Security scanning of Kubernetes manifests
  - Automated infrastructure deployment
  - Database and cache deployment
  - Monitoring stack deployment

### 2. Reusable Workflow
Backend services use a reusable workflow (`.github/workflows/backend-service-ci-cd.yml`) to avoid code duplication and ensure consistency.

### 3. Pipeline Benefits
- **Scalability**: Each service can be deployed independently
- **Efficiency**: Only affected services are rebuilt and deployed
- **Parallel Execution**: Multiple services can be deployed simultaneously
- **Isolation**: Service-specific issues don't affect other services
- **Maintainability**: Easier to manage and debug individual services

## Monitoring and Observability

### 1. Prometheus Metrics
All services expose metrics on `/metrics` endpoint:
- Application metrics
- Business metrics
- Infrastructure metrics

### 2. Grafana Dashboards
Access Grafana at: `http://your-cluster-ip:30000`
- Default credentials: admin/admin
- Import the dashboard from `kubernetes/monitoring.yaml`

### 3. Alerts
Configured alerts include:
- High CPU/Memory usage
- Pod failures
- Service unavailability

## Security Best Practices

### 1. Network Policies
- Restrict traffic between services
- Allow only necessary ports
- Implement least privilege access

### 2. Pod Security
- Run containers as non-root users
- Read-only root filesystem
- Drop unnecessary capabilities

### 3. Secrets Management
- Use Kubernetes secrets for sensitive data
- Rotate secrets regularly
- Encrypt secrets at rest

## Scaling and Performance

### 1. Horizontal Pod Autoscaling
All backend services have HPA configured:
- CPU threshold: 70%
- Memory threshold: 80%
- Min replicas: 2
- Max replicas: 10

### 2. Resource Limits
- CPU and memory limits defined
- Resource requests for scheduling
- Monitoring and alerting on resource usage

## Troubleshooting

### 1. Common Issues
```bash
# Check pod status
kubectl get pods -n stylehub

# Check pod logs
kubectl logs -f deployment/stylehub-ui -n stylehub

# Check service endpoints
kubectl get endpoints -n stylehub

# Check ingress status
kubectl get ingress -n stylehub
```

### 2. Debug Commands
```bash
# Port forward to access services locally
kubectl port-forward service/stylehub-ui-service 8080:80 -n stylehub

# Check ArgoCD application status
argocd app get stylehub

# Check Prometheus targets
kubectl port-forward service/prometheus-operated 9090:9090 -n monitoring
```

## Maintenance

### 1. Updates
- Update image tags in `kubernetes/kustomization.yaml`
- ArgoCD will automatically sync changes
- Monitor deployment health

### 2. Backup
- Database backups: Configure PostgreSQL backup strategy
- Configuration backups: Version control all manifests
- Application data: Use persistent volumes

### 3. Monitoring
- Regular health checks
- Performance monitoring
- Security scanning
- Log analysis

## Accessing the Application

### 1. Local Development
```bash
# Port forward to access services
kubectl port-forward service/stylehub-ui-service 3000:80 -n stylehub
kubectl port-forward service/stylehub-product-service 8081:8081 -n stylehub
```

### 2. Production Access
- Configure DNS to point to your ingress controller
- Update `stylehub.local` in ingress configuration
- Access via: `https://your-domain.com`

## Support and Documentation

For additional support:
- Check application logs
- Review monitoring dashboards
- Consult Kubernetes documentation
- Review ArgoCD documentation

## Security Considerations

1. **Network Security**: All inter-service communication is restricted by network policies
2. **Container Security**: Images are scanned for vulnerabilities with Trivy
3. **Secret Management**: Sensitive data is stored in Kubernetes secrets
4. **RBAC**: Implement proper role-based access control
5. **Audit Logging**: Enable Kubernetes audit logs
6. **Regular Updates**: Keep all components updated with security patches
