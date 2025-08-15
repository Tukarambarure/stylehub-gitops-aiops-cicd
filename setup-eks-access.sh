#!/bin/bash

# StyleHub EKS Setup and Access Script
# This script helps you connect to EKS, deploy the application, and access it

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="stylehub-cluster"
REGION="us-west-2"
NAMESPACE="stylehub"

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
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_status "AWS CLI is installed"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    print_status "kubectl is installed"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_status "AWS credentials are configured"
}

# Configure kubectl for EKS
configure_kubectl() {
    print_header "Configuring kubectl for EKS"
    
    print_status "Updating kubeconfig for EKS cluster: $CLUSTER_NAME"
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        print_status "Successfully connected to EKS cluster"
    else
        print_error "Failed to connect to EKS cluster"
        exit 1
    fi
    
    # Show cluster info
    echo -e "${BLUE}Cluster Information:${NC}"
    kubectl cluster-info
    echo ""
    
    # Show nodes
    echo -e "${BLUE}Cluster Nodes:${NC}"
    kubectl get nodes
    echo ""
}

# Deploy application
deploy_application() {
    print_header "Deploying StyleHub Application"
    
    # Create namespace if it doesn't exist
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy core infrastructure
    print_status "Deploying core infrastructure (namespace, configmaps, secrets, monitoring)"
    kubectl apply -k kubernetes/
    
    # Deploy application services
    print_status "Deploying UI service"
    kubectl apply -f kubernetes/ui/
    
    print_status "Deploying backend services"
    kubectl apply -f kubernetes/product-service/
    kubectl apply -f kubernetes/user-service/
    kubectl apply -f kubernetes/cart-service/
    kubectl apply -f kubernetes/order-service/
    
    print_status "Application deployment completed"
}

# Wait for deployment
wait_for_deployment() {
    print_header "Waiting for Application to be Ready"
    
    # Wait for pods to be ready
    print_status "Waiting for all pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=stylehub-ui -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-product-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-user-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-cart-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-order-service -n $NAMESPACE --timeout=300s
    
    print_status "All pods are ready"
}

# Show deployment status
show_status() {
    print_header "Application Status"
    
    echo -e "${BLUE}Pods:${NC}"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    echo -e "${BLUE}Services:${NC}"
    kubectl get svc -n $NAMESPACE
    echo ""
    
    echo -e "${BLUE}Ingress:${NC}"
    kubectl get ingress -n $NAMESPACE
    echo ""
    
    echo -e "${BLUE}Horizontal Pod Autoscalers:${NC}"
    kubectl get hpa -n $NAMESPACE
    echo ""
}

# Get application access information
get_access_info() {
    print_header "Application Access Information"
    
    # Get ALB DNS name
    ALB_DNS=$(kubectl get svc stylehub-ui-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ALB_DNS" ]; then
        echo -e "${GREEN}Application Load Balancer:${NC}"
        echo -e "${BLUE}URL:${NC} http://$ALB_DNS"
        echo -e "${BLUE}DNS Name:${NC} $ALB_DNS"
        echo ""
    else
        print_warning "ALB DNS name not available yet. It may take a few minutes to provision."
    fi
    
    # Get Ingress information
    INGRESS_HOST=$(kubectl get ingress stylehub-ui-ingress -n $NAMESPACE -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    
    if [ -n "$INGRESS_HOST" ]; then
        echo -e "${GREEN}Ingress Access:${NC}"
        echo -e "${BLUE}Host:${NC} $INGRESS_HOST"
        echo -e "${BLUE}Note:${NC} You need to configure DNS to point to the ALB IP"
        echo ""
    fi
    
    # Port forwarding option
    echo -e "${GREEN}Development Access (Port Forwarding):${NC}"
    echo -e "${BLUE}Command:${NC} kubectl port-forward svc/stylehub-ui-service 8080:80 -n $NAMESPACE"
    echo -e "${BLUE}URL:${NC} http://localhost:8080"
    echo ""
}

# Show useful commands
show_useful_commands() {
    print_header "Useful Commands"
    
    echo -e "${BLUE}View application logs:${NC}"
    echo "kubectl logs -f deployment/stylehub-ui -n $NAMESPACE"
    echo "kubectl logs -f deployment/stylehub-product-service -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}Check resource usage:${NC}"
    echo "kubectl top pods -n $NAMESPACE"
    echo "kubectl top nodes"
    echo ""
    
    echo -e "${BLUE}Scale services:${NC}"
    echo "kubectl scale deployment stylehub-ui --replicas=3 -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}View events:${NC}"
    echo "kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
    echo ""
    
    echo -e "${BLUE}Access shell in container:${NC}"
    echo "kubectl exec -it deployment/stylehub-ui -n $NAMESPACE -- /bin/bash"
    echo ""
}

# Main function
main() {
    print_header "StyleHub EKS Setup and Access"
    
    check_prerequisites
    configure_kubectl
    deploy_application
    wait_for_deployment
    show_status
    get_access_info
    show_useful_commands
    
    print_status "Setup completed successfully!"
    echo ""
    print_warning "If ALB DNS is not available immediately, wait a few minutes and run:"
    echo "kubectl get svc stylehub-ui-loadbalancer -n $NAMESPACE"
}

# Run main function
main "$@"
