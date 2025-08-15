# ArgoCD Setup and Management Guide

This guide explains how to install ArgoCD on your EKS cluster and use it to manage StyleHub deployments through a web interface.

## 🚀 Quick Start

### 1. Install ArgoCD

```bash
# Make script executable
chmod +x setup-argocd.sh

# Run the complete ArgoCD setup
./setup-argocd.sh
```

### 2. Access ArgoCD Web UI

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward ArgoCD (for development)
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# Access at: https://localhost:8080
# Username: admin
# Password: (from command above)
```

## 🔧 Manual Installation

### Step 1: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### Step 2: Configure ArgoCD Load Balancer

```bash
# Apply LoadBalancer service for ArgoCD
kubectl apply -f argocd/argocd-server-service.yaml

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 3: Create ArgoCD Applications

```bash
# Apply ArgoCD applications
kubectl apply -f argocd/applications.yaml
```

## 🌐 Accessing ArgoCD

### Option 1: Load Balancer (Production)

```bash
# Get ArgoCD Load Balancer DNS
kubectl get svc argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Access at: https://<alb-dns-name>
# Username: admin
# Password: (get from secret)
```

### Option 2: Port Forwarding (Development)

```bash
# Port forward ArgoCD
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# Access at: https://localhost:8080
# Username: admin
# Password: (get from secret)
```

### Option 3: Ingress (with SSL)

```bash
# Apply ArgoCD Ingress
kubectl apply -f argocd/argocd-ingress.yaml

# Access at: https://argocd.yourdomain.com
```

## 📊 Using ArgoCD Web Interface

### 1. Dashboard Overview

The ArgoCD dashboard shows:
- **Applications**: All your StyleHub applications
- **Status**: Health and sync status of each app
- **Resources**: Kubernetes resources managed by ArgoCD
- **Settings**: ArgoCD configuration

### 2. Application Management

#### View Applications
- Click on any application to see details
- View resource tree, events, and logs
- Check sync status and health

#### Sync Applications
- **Manual Sync**: Click "Sync" button for immediate deployment
- **Auto Sync**: Applications sync automatically when Git changes
- **Selective Sync**: Choose specific resources to sync

#### Application Actions
- **Sync**: Deploy latest changes
- **Refresh**: Check for new Git commits
- **Rollback**: Revert to previous version
- **Delete**: Remove application from cluster

### 3. Resource Management

#### View Resources
- **Tree View**: Hierarchical view of Kubernetes resources
- **Network View**: Visual representation of resource relationships
- **List View**: Tabular view of all resources

#### Resource Actions
- **View YAML**: See resource definition
- **View Logs**: Access pod logs
- **Describe**: Get detailed resource information
- **Delete**: Remove specific resources

## 🔄 GitOps Workflow

### 1. Development Workflow

```bash
# 1. Make changes to Kubernetes manifests
git add kubernetes/
git commit -m "Update deployment configuration"
git push origin main

# 2. ArgoCD automatically detects changes
# 3. ArgoCD syncs changes to cluster
# 4. Monitor deployment in ArgoCD UI
```

### 2. Deployment Strategies

#### Blue-Green Deployment
```yaml
# In your ArgoCD application
spec:
  syncPolicy:
    syncOptions:
      - PruneLast=true
      - CreateNamespace=true
```

#### Rolling Update
```yaml
# In your deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### 3. Environment Promotion

```bash
# Promote from dev to staging
argocd app sync stylehub --revision staging

# Promote from staging to production
argocd app sync stylehub --revision production
```

## 🛠️ ArgoCD CLI Usage

### Install ArgoCD CLI

```bash
# Download ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <password>
```

### Useful CLI Commands

```bash
# List applications
argocd app list

# Get application status
argocd app get stylehub

# Sync application
argocd app sync stylehub

# View application logs
argocd app logs stylehub

# Rollback application
argocd app rollback stylehub

# Delete application
argocd app delete stylehub

# Get application resources
argocd app resources stylehub

# View application events
argocd app events stylehub
```

## 📈 Monitoring and Observability

### 1. Application Health

ArgoCD provides health status:
- **Healthy**: All resources are in desired state
- **Degraded**: Some resources have issues
- **Missing**: Resources don't exist in cluster
- **Unknown**: Health status cannot be determined

### 2. Sync Status

- **Synced**: Cluster matches Git state
- **Out of Sync**: Cluster differs from Git
- **Unknown**: Sync status cannot be determined

### 3. Resource Events

```bash
# View application events
argocd app events stylehub

# View resource events in ArgoCD UI
# Navigate to Application > Events tab
```

## 🔐 Security and RBAC

### 1. User Management

```bash
# Create new user
argocd account create-user --username developer --password <password>

# Update user password
argocd account update-password --username developer --current-password <old> --new-password <new>
```

### 2. RBAC Configuration

```yaml
# Configure RBAC in ArgoCD
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:org-admin, applications, *, */*, allow
    p, role:org-admin, clusters, *, *, allow
    p, role:org-admin, repositories, *, *, allow
    p, role:org-admin, projects, *, *, allow
    p, role:org-admin, accounts, *, *, allow
    p, role:org-admin, gpgkeys, *, *, allow
    p, role:org-admin, certificates, *, *, allow
    g, admin, role:org-admin
    g, developer, role:readonly
```

### 3. SSO Integration

```yaml
# Configure SSO (example with OIDC)
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.yourdomain.com
  oidc.config: |
    name: Okta
    issuer: https://your-okta-domain.okta.com
    clientID: your-client-id
    clientSecret: your-client-secret
    requestedScopes: [openid, profile, email, groups]
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Application Out of Sync

```bash
# Check application status
argocd app get stylehub

# Force sync
argocd app sync stylehub --force

# Check Git repository
argocd app get stylehub --output yaml
```

#### 2. Sync Failures

```bash
# View sync logs
argocd app logs stylehub

# Check application events
argocd app events stylehub

# Verify Git repository access
argocd repo list
```

#### 3. Resource Health Issues

```bash
# Check resource status
kubectl get all -n stylehub

# View pod logs
kubectl logs -f deployment/stylehub-ui -n stylehub

# Check events
kubectl get events -n stylehub --sort-by='.lastTimestamp'
```

### Debugging Commands

```bash
# Get ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Get ArgoCD application controller logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Get ArgoCD repo server logs
kubectl logs -f deployment/argocd-repo-server -n argocd

# Check ArgoCD configuration
kubectl get configmaps -n argocd
kubectl get secrets -n argocd
```

## 🎯 Best Practices

### 1. Application Structure

- **Separate applications** for different services
- **Use Kustomize** for environment-specific configurations
- **Version your manifests** with Git tags

### 2. Sync Policies

- **Enable auto-sync** for development environments
- **Manual sync** for production environments
- **Use sync waves** for dependency ordering

### 3. Security

- **Use RBAC** to control access
- **Enable SSO** for enterprise environments
- **Audit logs** for compliance

### 4. Monitoring

- **Set up alerts** for sync failures
- **Monitor application health** regularly
- **Use ArgoCD notifications** for events

## 📞 Support

For issues and questions:

1. [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
2. [ArgoCD GitHub Repository](https://github.com/argoproj/argo-cd)
3. [ArgoCD Community](https://argoproj.github.io/community/)

---

**Happy GitOps! 🚀**
