# ArgoCD Quick Reference Guide

## 🚀 Quick Setup

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml

# 2. Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 3. Port forward for access
kubectl port-forward svc/argocd-server 8080:443 -n argocd

# 4. Access at: https://localhost:8080
# Username: admin
# Password: (from step 2)
```

## 🌐 Access Methods

### Port Forwarding (Development)
```bash
kubectl port-forward svc/argocd-server 8080:443 -n argocd
# Access: https://localhost:8080
```

### Load Balancer (Production)
```bash
# Apply LoadBalancer service
kubectl apply -f argocd/argocd-server-service.yaml

# Get DNS name
kubectl get svc argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# Access: https://<dns-name>
```

## 📱 Web UI Navigation

### Main Dashboard
- **Applications**: View all managed applications
- **Clusters**: Manage Kubernetes clusters
- **Repositories**: Git repositories
- **Projects**: Organize applications
- **Settings**: ArgoCD configuration

### Application View
- **Tree View**: Resource hierarchy
- **Network View**: Resource relationships
- **List View**: Tabular resource list
- **Events**: Application events
- **Logs**: Application logs

## 🛠️ Common Operations

### Application Management

#### Create Application
```bash
# Via CLI
argocd app create stylehub \
  --repo https://github.com/your-username/stylehub.git \
  --path kubernetes \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace stylehub

# Via YAML
kubectl apply -f argocd/applications.yaml
```

#### Sync Application
```bash
# Manual sync
argocd app sync stylehub

# Force sync
argocd app sync stylehub --force

# Selective sync
argocd app sync stylehub --resource Deployment:stylehub-ui
```

#### Check Status
```bash
# List applications
argocd app list

# Get application details
argocd app get stylehub

# View application resources
argocd app resources stylehub
```

#### Rollback
```bash
# List revisions
argocd app history stylehub

# Rollback to specific revision
argocd app rollback stylehub 2
```

### Resource Management

#### View Resources
```bash
# Get resource tree
argocd app resources stylehub --tree

# Get resource list
argocd app resources stylehub --list

# Get specific resource
argocd app resources stylehub --resource Deployment:stylehub-ui
```

#### Resource Actions
```bash
# View resource YAML
argocd app resources stylehub --resource Deployment:stylehub-ui --output yaml

# View resource logs
argocd app logs stylehub --resource Deployment:stylehub-ui

# Delete resource
argocd app resources stylehub --resource Deployment:stylehub-ui --delete
```

## 🔄 GitOps Workflow

### Development Workflow
```bash
# 1. Make changes to manifests
git add kubernetes/
git commit -m "Update deployment"
git push origin main

# 2. ArgoCD auto-syncs (if enabled)
# 3. Monitor in ArgoCD UI
# 4. Verify deployment
```

### Manual Sync Workflow
```bash
# 1. Make changes to manifests
git add kubernetes/
git commit -m "Update deployment"
git push origin main

# 2. Manual sync
argocd app sync stylehub

# 3. Monitor sync status
argocd app get stylehub
```

## 📊 Monitoring Commands

### Application Health
```bash
# Check health status
argocd app get stylehub --output wide

# View health details
argocd app get stylehub --output yaml | grep -A 10 "health"
```

### Sync Status
```bash
# Check sync status
argocd app get stylehub --output wide

# View sync details
argocd app get stylehub --output yaml | grep -A 10 "sync"
```

### Events and Logs
```bash
# View application events
argocd app events stylehub

# View application logs
argocd app logs stylehub

# View resource logs
argocd app logs stylehub --resource Deployment:stylehub-ui
```

## 🔐 Security Commands

### User Management
```bash
# Create user
argocd account create-user --username developer --password <password>

# Update password
argocd account update-password --username developer --current-password <old> --new-password <new>

# Delete user
argocd account delete-user --username developer
```

### Authentication
```bash
# Login
argocd login localhost:8080 --username admin --password <password>

# Login with token
argocd login localhost:8080 --auth-token <token>

# Logout
argocd logout localhost:8080
```

## 🔍 Troubleshooting

### Common Issues

#### Application Out of Sync
```bash
# Check status
argocd app get stylehub

# Force sync
argocd app sync stylehub --force

# Check Git repository
argocd repo list
```

#### Sync Failures
```bash
# View sync logs
argocd app logs stylehub

# Check events
argocd app events stylehub

# Verify repository access
argocd repo get https://github.com/your-username/stylehub.git
```

#### Resource Health Issues
```bash
# Check resource status
kubectl get all -n stylehub

# View pod logs
kubectl logs -f deployment/stylehub-ui -n stylehub

# Check events
kubectl get events -n stylehub --sort-by='.lastTimestamp'
```

### Debugging
```bash
# ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# Application controller logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Repo server logs
kubectl logs -f deployment/argocd-repo-server -n argocd
```

## 📋 Useful Aliases

```bash
# Add to your .bashrc or .zshrc
alias argocd-apps='argocd app list'
alias argocd-sync='argocd app sync'
alias argocd-status='argocd app get'
alias argocd-logs='argocd app logs'
alias argocd-events='argocd app events'
alias argocd-resources='argocd app resources'
```

## 🎯 Best Practices

### Application Configuration
- Use separate applications for different services
- Enable auto-sync for development, manual for production
- Use sync waves for dependency ordering
- Set appropriate revision history limits

### Security
- Use RBAC to control access
- Enable SSO for enterprise environments
- Regularly rotate admin passwords
- Audit application changes

### Monitoring
- Set up alerts for sync failures
- Monitor application health regularly
- Use ArgoCD notifications for events
- Keep ArgoCD version updated

---

**Quick Tips:**
- Use `argocd app get <app-name> --output yaml` to see full configuration
- Use `argocd app sync <app-name> --dry-run` to preview changes
- Use `argocd app diff <app-name>` to see differences between Git and cluster
- Use `argocd app history <app-name>` to view deployment history
