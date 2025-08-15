#!/bin/bash

# StyleHub Kubernetes Deployment Script
# This script automates the deployment of the StyleHub application on Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="stylehub"
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        print_status "Creating namespace $NAMESPACE"
        kubectl apply -f kubernetes/namespace.yaml
    fi
}

# Function to deploy infrastructure components
deploy_infrastructure() {
    print_status "Deploying infrastructure components..."
    
    # Deploy configmaps and secrets
    kubectl apply -f kubernetes/configmaps.yaml
    kubectl apply -f kubernetes/secrets.yaml
    
    # Deploy database and cache
    kubectl apply -f kubernetes/database.yaml
    kubectl apply -f kubernetes/redis.yaml
    
    # Deploy monitoring
    kubectl apply -f kubernetes/monitoring.yaml
    
    # Apply network policies
    kubectl apply -f kubernetes/network-policy.yaml
    
    print_status "Infrastructure components deployed successfully"
}

# Function to deploy application services
deploy_application() {
    print_status "Deploying application services..."
    
    # Update image tags in kustomization
    sed -i "s/newTag: \${IMAGE_TAG}/newTag: $IMAGE_TAG/g" kubernetes/kustomization.yaml
    sed -i "s/\${DOCKER_USERNAME}/$DOCKER_USERNAME/g" kubernetes/kustomization.yaml
    
    # Deploy using kustomize
    kubectl apply -k kubernetes/
    
    print_status "Application services deployed successfully"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for database
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s
    
    # Wait for redis
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s
    
    # Wait for backend services
    kubectl wait --for=condition=ready pod -l app=stylehub-product-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-user-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-cart-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-order-service -n $NAMESPACE --timeout=300s
    
    # Wait for frontend
    kubectl wait --for=condition=ready pod -l app=stylehub-ui -n $NAMESPACE --timeout=300s
    
    print_status "All services are ready"
}

# Function to check deployment status
check_deployment_status() {
    print_status "Checking deployment status..."
    
    echo "Pod Status:"
    kubectl get pods -n $NAMESPACE
    
    echo -e "\nService Status:"
    kubectl get services -n $NAMESPACE
    
    echo -e "\nIngress Status:"
    kubectl get ingress -n $NAMESPACE
    
    echo -e "\nHPA Status:"
    kubectl get hpa -n $NAMESPACE
}

# Function to setup port forwarding for local access
setup_port_forward() {
    print_status "Setting up port forwarding for local access..."
    
    echo "Port forwarding setup:"
    echo "Frontend: http://localhost:3000"
    echo "Product Service: http://localhost:8081"
    echo "User Service: http://localhost:8082"
    echo "Cart Service: http://localhost:8083"
    echo "Order Service: http://localhost:8084"
    
    # Start port forwarding in background
    kubectl port-forward service/stylehub-ui-service 3000:80 -n $NAMESPACE &
    kubectl port-forward service/stylehub-product-service 8081:8081 -n $NAMESPACE &
    kubectl port-forward service/stylehub-user-service 8082:8082 -n $NAMESPACE &
    kubectl port-forward service/stylehub-cart-service 8083:8083 -n $NAMESPACE &
    kubectl port-forward service/stylehub-order-service 8084:8084 -n $NAMESPACE &
    
    print_status "Port forwarding started. Press Ctrl+C to stop."
    
    # Wait for user to stop
    wait
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up port forwarding..."
    pkill -f "kubectl port-forward" || true
}

# Main deployment function
main() {
    print_status "Starting StyleHub deployment..."
    
    # Check prerequisites
    check_kubectl
    
    # Check and create namespace
    check_namespace
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy application
    deploy_application
    
    # Wait for services
    wait_for_services
    
    # Check status
    check_deployment_status
    
    print_status "Deployment completed successfully!"
    print_status "You can now access the application using port forwarding or ingress."
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -d, --deploy            Deploy the application"
    echo "  -s, --status            Check deployment status"
    echo "  -p, --port-forward      Setup port forwarding for local access"
    echo "  -c, --cleanup           Clean up port forwarding"
    echo "  -u, --username USERNAME Docker Hub username"
    echo "  -t, --tag TAG           Docker image tag"
    echo ""
    echo "Environment variables:"
    echo "  DOCKER_USERNAME         Docker Hub username"
    echo "  IMAGE_TAG               Docker image tag"
    echo ""
    echo "Examples:"
    echo "  $0 --deploy"
    echo "  $0 --deploy --username myuser --tag v1.0.0"
    echo "  $0 --status"
    echo "  $0 --port-forward"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -d|--deploy)
        main
        ;;
    -s|--status)
        check_deployment_status
        ;;
    -p|--port-forward)
        setup_port_forward
        ;;
    -c|--cleanup)
        cleanup
        ;;
    -u|--username)
        DOCKER_USERNAME="$2"
        shift 2
        main
        ;;
    -t|--tag)
        IMAGE_TAG="$2"
        shift 2
        main
        ;;
    *)
        usage
        exit 1
        ;;
esac

# Set up trap to cleanup on exit
trap cleanup EXIT
