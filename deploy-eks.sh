#!/bin/bash

# StyleHub EKS Deployment Script
# This script automates the deployment of the StyleHub application on AWS EKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="stylehub"
CLUSTER_NAME=${EKS_CLUSTER_NAME:-"stylehub-cluster"}
AWS_REGION=${AWS_REGION:-"us-west-2"}
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

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if aws CLI is available
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        print_warning "Helm is not installed. Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    print_status "Prerequisites check completed"
}

# Function to configure AWS and EKS
configure_aws_eks() {
    print_header "Configuring AWS and EKS..."
    
    # Configure AWS credentials
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        print_error "AWS credentials not found. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
        exit 1
    fi
    
    # Update kubeconfig
    print_status "Updating kubeconfig for EKS cluster: $CLUSTER_NAME"
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
    
    # Verify cluster access
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot access EKS cluster. Please check your AWS credentials and cluster name."
        exit 1
    fi
    
    print_status "AWS and EKS configuration completed"
}

# Function to install EKS add-ons
install_eks_addons() {
    print_header "Installing EKS add-ons..."
    
    # Install AWS Load Balancer Controller
    print_status "Installing AWS Load Balancer Controller..."
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=$CLUSTER_NAME \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
    
    # Install EBS CSI Driver
    print_status "Installing EBS CSI Driver..."
    helm install aws-ebs-csi-driver eks/aws-ebs-csi-driver \
        -n kube-system \
        --set controller.serviceAccount.create=false \
        --set controller.serviceAccount.name=ebs-csi-controller-sa
    
    # Install NGINX Ingress Controller
    print_status "Installing NGINX Ingress Controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        -n ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --set controller.ingressClassResource.name=nginx
    
    # Install cert-manager
    print_status "Installing cert-manager..."
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    helm install cert-manager jetstack/cert-manager \
        -n cert-manager \
        --create-namespace \
        --set installCRDs=true \
        --set global.leaderElection.namespace=cert-manager
    
    print_status "EKS add-ons installation completed"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying infrastructure components..."
    
    # Create namespace
    print_status "Creating namespace: $NAMESPACE"
    kubectl apply -f kubernetes/namespace.yaml
    
    # Deploy storage class
    print_status "Deploying EKS storage class..."
    kubectl apply -f kubernetes/eks-storage-class.yaml
    
    # Deploy configmaps and secrets
    print_status "Deploying configmaps and secrets..."
    kubectl apply -f kubernetes/configmaps.yaml
    kubectl apply -f kubernetes/secrets.yaml
    
    # Deploy database
    print_status "Deploying PostgreSQL database..."
    kubectl apply -f kubernetes/database.yaml
    kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s
    
    # Deploy redis
    print_status "Deploying Redis cache..."
    kubectl apply -f kubernetes/redis.yaml
    kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s
    
    # Deploy monitoring
    print_status "Deploying monitoring stack..."
    kubectl apply -f kubernetes/monitoring.yaml
    
    # Deploy network policies
    print_status "Deploying network policies..."
    kubectl apply -f kubernetes/network-policy.yaml
    
    print_status "Infrastructure deployment completed"
}

# Function to deploy application services
deploy_application() {
    print_header "Deploying application services..."
    
    # Update image tags in kustomization
    print_status "Updating image tags..."
    sed -i "s/newTag: \${IMAGE_TAG}/newTag: $IMAGE_TAG/g" kubernetes/kustomization.yaml
    sed -i "s/\${DOCKER_USERNAME}/$DOCKER_USERNAME/g" kubernetes/kustomization.yaml
    
    # Deploy all services using kustomize
    print_status "Deploying all services..."
    kubectl apply -k kubernetes/
    
    # Wait for all services to be ready
    print_status "Waiting for services to be ready..."
    kubectl wait --for=condition=ready pod -l app=stylehub-ui -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-product-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-user-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-cart-service -n $NAMESPACE --timeout=300s
    kubectl wait --for=condition=ready pod -l app=stylehub-order-service -n $NAMESPACE --timeout=300s
    
    print_status "Application deployment completed"
}

# Function to verify deployment
verify_deployment() {
    print_header "Verifying deployment..."
    
    echo "Pod Status:"
    kubectl get pods -n $NAMESPACE
    
    echo -e "\nService Status:"
    kubectl get services -n $NAMESPACE
    
    echo -e "\nIngress Status:"
    kubectl get ingress -n $NAMESPACE
    
    echo -e "\nHPA Status:"
    kubectl get hpa -n $NAMESPACE
    
    echo -e "\nPersistent Volume Claims:"
    kubectl get pvc -n $NAMESPACE
    
    # Get Load Balancer URL
    echo -e "\nLoad Balancer URL:"
    kubectl get service stylehub-ui-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    echo ""
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -d, --deploy            Deploy the complete application"
    echo "  -i, --infrastructure    Deploy only infrastructure"
    echo "  -a, --addons            Install EKS add-ons only"
    echo "  -v, --verify            Verify deployment status"
    echo "  -c, --cluster NAME      EKS cluster name (default: stylehub-cluster)"
    echo "  -r, --region REGION     AWS region (default: us-west-2)"
    echo "  -u, --username USERNAME Docker Hub username"
    echo "  -t, --tag TAG           Docker image tag"
    echo ""
    echo "Environment variables:"
    echo "  EKS_CLUSTER_NAME        EKS cluster name"
    echo "  AWS_REGION              AWS region"
    echo "  AWS_ACCESS_KEY_ID       AWS access key"
    echo "  AWS_SECRET_ACCESS_KEY   AWS secret key"
    echo "  DOCKER_USERNAME         Docker Hub username"
    echo "  IMAGE_TAG               Docker image tag"
    echo ""
    echo "Examples:"
    echo "  $0 --deploy"
    echo "  $0 --deploy --cluster my-cluster --region us-east-1"
    echo "  $0 --infrastructure"
    echo "  $0 --verify"
}

# Main deployment function
main() {
    print_header "Starting StyleHub EKS deployment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Configure AWS and EKS
    configure_aws_eks
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy application
    deploy_application
    
    # Verify deployment
    verify_deployment
    
    print_status "EKS deployment completed successfully!"
    print_status "You can now access the application using the Load Balancer URL above."
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
    -i|--infrastructure)
        check_prerequisites
        configure_aws_eks
        deploy_infrastructure
        verify_deployment
        ;;
    -a|--addons)
        check_prerequisites
        configure_aws_eks
        install_eks_addons
        ;;
    -v|--verify)
        configure_aws_eks
        verify_deployment
        ;;
    -c|--cluster)
        CLUSTER_NAME="$2"
        shift 2
        main
        ;;
    -r|--region)
        AWS_REGION="$2"
        shift 2
        main
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
