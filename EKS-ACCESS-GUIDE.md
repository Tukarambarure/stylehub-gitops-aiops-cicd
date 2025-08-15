# EKS Access and Application Exposure Guide

This guide explains how to connect to your EKS cluster, deploy the application, and access it from your browser.

## 🚀 Quick Start

### 1. Run the Setup Script

```bash
# Make script executable
chmod +x setup-eks-access.sh

# Run the complete setup
./setup-eks-access.sh
```

This script will:
- ✅ Check prerequisites (AWS CLI, kubectl)
- ✅ Configure kubectl for EKS
- ✅ Deploy the application
- ✅ Show access information
- ✅ Provide useful commands

## 🔧 Manual Setup (Step by Step)

### Step 1: Configure kubectl for EKS

```bash
# Connect to your EKS cluster
aws eks update-kubeconfig --region us-west-2 --name stylehub-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 2: Deploy the Application

```bash
# Deploy core infrastructure
kubectl apply -k kubernetes/

# Deploy application services
kubectl apply -f kubernetes/ui/
kubectl apply -f kubernetes/product-service/
kubectl apply -f kubernetes/user-service/
kubectl apply -f kubernetes/cart-service/
kubectl apply -f kubernetes/order-service/
```

### Step 3: Verify Deployment

```bash
# Check all resources
kubectl get all -n stylehub

# Check specific resources
kubectl get pods -n stylehub
kubectl get svc -n stylehub
kubectl get ingress -n stylehub
kubectl get hpa -n stylehub
```

## 🌐 Accessing Your Application

### Option 1: Application Load Balancer (Recommended)

The infrastructure automatically creates an ALB. Get the DNS name:

```bash
# Get ALB DNS name
kubectl get svc stylehub-ui-loadbalancer -n stylehub -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or use Terraform output
cd terraform
terraform output alb_dns_name
```

**Access your application at:** `http://<alb-dns-name>`

### Option 2: Ingress (with DNS Configuration)

The application includes an Ingress resource:

```bash
# Check ingress status
kubectl get ingress -n stylehub
kubectl describe ingress stylehub-ui-ingress -n stylehub
```

**Access your application at:** `http://stylehub.local` (after DNS configuration)

### Option 3: Port Forwarding (Development)

For local development and testing:

```bash
# Forward local port to UI service
kubectl port-forward svc/stylehub-ui-service 8080:80 -n stylehub

# Access at: http://localhost:8080
```

## 📊 Monitoring and Troubleshooting

### Check Application Status

```bash
# View all pods
kubectl get pods -n stylehub

# View pod details
kubectl describe pod <pod-name> -n stylehub

# View pod logs
kubectl logs <pod-name> -n stylehub
kubectl logs -f deployment/stylehub-ui -n stylehub
```

### Check Services

```bash
# View all services
kubectl get svc -n stylehub

# View service details
kubectl describe svc stylehub-ui-service -n stylehub

# Check endpoints
kubectl get endpoints -n stylehub
```

### Check Ingress

```bash
# View ingress status
kubectl get ingress -n stylehub

# View ingress details
kubectl describe ingress stylehub-ui-ingress -n stylehub
```

### Resource Usage

```bash
# Check pod resource usage
kubectl top pods -n stylehub

# Check node resource usage
kubectl top nodes

# Check HPA status
kubectl get hpa -n stylehub
kubectl describe hpa -n stylehub
```

## 🔍 Troubleshooting Common Issues

### Issue 1: Cannot Connect to EKS

```bash
# Check AWS credentials
aws sts get-caller-identity

# Reconfigure kubectl
aws eks update-kubeconfig --region us-west-2 --name stylehub-cluster

# Check cluster status
aws eks describe-cluster --name stylehub-cluster --region us-west-2
```

### Issue 2: Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n stylehub

# Check pod logs
kubectl logs <pod-name> -n stylehub

# Check events
kubectl get events -n stylehub --sort-by='.lastTimestamp'
```

### Issue 3: ALB Not Available

```bash
# Check ALB service
kubectl get svc stylehub-ui-loadbalancer -n stylehub

# Check ALB controller logs
kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

# Wait a few minutes for ALB provisioning
```

### Issue 4: Application Not Accessible

```bash
# Check if pods are ready
kubectl get pods -n stylehub

# Check service endpoints
kubectl get endpoints -n stylehub

# Test service connectivity
kubectl port-forward svc/stylehub-ui-service 8080:80 -n stylehub
# Then access http://localhost:8080
```

## 🛠️ Useful Commands

### Scaling

```bash
# Scale UI service
kubectl scale deployment stylehub-ui --replicas=3 -n stylehub

# Scale backend services
kubectl scale deployment stylehub-product-service --replicas=2 -n stylehub
kubectl scale deployment stylehub-user-service --replicas=2 -n stylehub
```

### Debugging

```bash
# Access shell in container
kubectl exec -it deployment/stylehub-ui -n stylehub -- /bin/bash

# View real-time logs
kubectl logs -f deployment/stylehub-ui -n stylehub

# Check resource limits
kubectl describe pod <pod-name> -n stylehub | grep -A 5 "Limits:"
```

### Configuration

```bash
# View configmaps
kubectl get configmaps -n stylehub
kubectl describe configmap <configmap-name> -n stylehub

# View secrets
kubectl get secrets -n stylehub
kubectl describe secret <secret-name> -n stylehub
```

## 🔐 Security Considerations

### Network Access

- **ALB**: Public internet access
- **Services**: Internal cluster access only
- **Pods**: No direct external access

### Authentication

- **EKS**: Uses AWS IAM for cluster access
- **Application**: Configure authentication as needed
- **Secrets**: Stored in Kubernetes secrets

## 📈 Monitoring

### CloudWatch Dashboard

Access the CloudWatch dashboard to monitor:
- ALB metrics (request count, response time, error rates)
- EKS cluster metrics (node count, failed nodes)
- Application metrics (CPU, memory, custom metrics)

### Logs

Application logs are available in CloudWatch:
- Application logs: `/aws/application/stylehub-production`
- EKS logs: `/aws/eks/stylehub-production/cluster`
- ALB logs: `/aws/applicationloadbalancer/stylehub-production`

## 🎯 Next Steps

1. **Configure DNS**: Point your domain to the ALB DNS name
2. **SSL Certificate**: Configure SSL/TLS termination at the ALB
3. **Monitoring**: Set up additional monitoring tools if needed
4. **Backup**: Configure automated backups for persistent data
5. **CI/CD**: Use the provided GitHub Actions pipelines for automated deployments

## 📞 Support

For issues and questions:

1. Check the [AWS EKS documentation](https://docs.aws.amazon.com/eks/)
2. Review the [Kubernetes documentation](https://kubernetes.io/docs/)
3. Check the [AWS Load Balancer Controller documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

---

**Happy deploying! 🚀**
