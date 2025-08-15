#!/bin/bash

# ArgoCD Setup Script for StyleHub EKS
# This script installs ArgoCD and configures it for managing StyleHub deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="argocd"
ARGOCD_VERSION="v2.8.4"

# Print functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_status "kubectl is installed"
    
    # Check if connected to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to Kubernetes cluster"
        exit 1
    fi
    print_status "Connected to Kubernetes cluster"
}

# Install ArgoCD
install_argocd() {
    print_header "Installing ArgoCD"
    
    # Create namespace
    print_status "Creating ArgoCD namespace"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    print_status "Installing ArgoCD version $ARGOCD_VERSION"
    kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available deployment/argocd-server -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=available deployment/argocd-repo-server -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=available deployment/argocd-application-controller -n $NAMESPACE --timeout=300s
    
    print_status "ArgoCD installation completed"
}

# Configure ArgoCD
configure_argocd() {
    print_header "Configuring ArgoCD"
    
    # Get initial admin password
    print_status "Getting initial admin password"
    INITIAL_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo -e "${BLUE}Initial ArgoCD Admin Password:${NC} $INITIAL_PASSWORD"
    echo -e "${YELLOW}Please save this password!${NC}"
    echo ""
    
    # Change admin password (optional)
    read -p "Do you want to change the admin password? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -s -p "Enter new admin password: " NEW_PASSWORD
        echo
        kubectl -n $NAMESPACE patch secret argocd-secret -p '{"stringData":{"admin.password":"'$(echo -n $NEW_PASSWORD | base64)'"}}'
        print_status "Admin password updated"
    fi
    
    # Configure RBAC (optional)
    print_status "Configuring RBAC"
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: $NAMESPACE
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
EOF
    
    print_status "ArgoCD configuration completed"
}

# Create ArgoCD applications
create_applications() {
    print_header "Creating ArgoCD Applications"
    
    # Create StyleHub application
    print_status "Creating StyleHub application"
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 10
EOF
    
    # Create individual service applications
    print_status "Creating individual service applications"
    
    # UI Application
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub-ui
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes/ui
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 5
EOF
    
    # Product Service Application
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub-product-service
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes/product-service
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 5
EOF
    
    # User Service Application
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub-user-service
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes/user-service
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 5
EOF
    
    # Cart Service Application
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub-cart-service
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes/cart-service
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 5
EOF
    
    # Order Service Application
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stylehub-order-service
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/stylehub.git
    targetRevision: HEAD
    path: kubernetes/order-service
  destination:
    server: https://kubernetes.default.svc
    namespace: stylehub
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
  revisionHistoryLimit: 5
EOF
    
    print_status "ArgoCD applications created"
}

# Show access information
show_access_info() {
    print_header "ArgoCD Access Information"
    
    # Get ArgoCD server service
    ARGOCD_SERVICE=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ARGOCD_SERVICE" ]; then
        echo -e "${GREEN}ArgoCD Load Balancer:${NC}"
        echo -e "${BLUE}URL:${NC} https://$ARGOCD_SERVICE"
        echo -e "${BLUE}Username:${NC} admin"
        echo -e "${BLUE}Password:${NC} (see above or check secret)"
        echo ""
    else
        print_warning "ArgoCD Load Balancer not available yet. Using port forwarding..."
        echo ""
    fi
    
    # Port forwarding option
    echo -e "${GREEN}Development Access (Port Forwarding):${NC}"
    echo -e "${BLUE}Command:${NC} kubectl port-forward svc/argocd-server 8080:443 -n $NAMESPACE"
    echo -e "${BLUE}URL:${NC} https://localhost:8080"
    echo -e "${BLUE}Username:${NC} admin"
    echo -e "${BLUE}Password:${NC} (see above or check secret)"
    echo ""
    
    # Get password again
    PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Check secret manually")
    echo -e "${BLUE}Current Admin Password:${NC} $PASSWORD"
    echo ""
}

# Show useful commands
show_useful_commands() {
    print_header "Useful ArgoCD Commands"
    
    echo -e "${BLUE}Get ArgoCD admin password:${NC}"
    echo "kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d"
    echo ""
    
    echo -e "${BLUE}List ArgoCD applications:${NC}"
    echo "kubectl get applications -n $NAMESPACE"
    echo "argocd app list"
    echo ""
    
    echo -e "${BLUE}Sync applications:${NC}"
    echo "argocd app sync stylehub"
    echo "argocd app sync stylehub-ui"
    echo ""
    
    echo -e "${BLUE}Get application status:${NC}"
    echo "argocd app get stylehub"
    echo "kubectl get applications -n $NAMESPACE -o yaml"
    echo ""
    
    echo -e "${BLUE}View application logs:${NC}"
    echo "argocd app logs stylehub"
    echo "kubectl logs -f deployment/argocd-application-controller -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}Port forward ArgoCD:${NC}"
    echo "kubectl port-forward svc/argocd-server 8080:443 -n $NAMESPACE"
    echo ""
}

# Main function
main() {
    print_header "ArgoCD Setup for StyleHub"
    
    check_prerequisites
    install_argocd
    configure_argocd
    create_applications
    show_access_info
    show_useful_commands
    
    print_status "ArgoCD setup completed successfully!"
    echo ""
    print_warning "Remember to:"
    echo "1. Update the GitHub repository URL in the applications"
    echo "2. Configure your Git repository with the Kubernetes manifests"
    echo "3. Set up webhooks for automatic sync (optional)"
}

# Run main function
main "$@"
