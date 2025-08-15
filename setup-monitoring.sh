#!/bin/bash

# Kubernetes Monitoring Setup Script
# This script installs Prometheus, Grafana, and related monitoring tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="monitoring"
PROMETHEUS_STACK_VERSION="55.5.0"
GRAFANA_VERSION="7.0.3"

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
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi
    print_status "helm is installed"
    
    # Check if connected to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to Kubernetes cluster"
        exit 1
    fi
    print_status "Connected to Kubernetes cluster"
}

# Add Helm repositories
add_helm_repos() {
    print_header "Adding Helm Repositories"
    
    print_status "Adding Prometheus-community repository"
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    print_status "Helm repositories added and updated"
}

# Create monitoring namespace
create_namespace() {
    print_header "Creating Monitoring Namespace"
    
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "Namespace created"
}

# Install Prometheus Stack
install_prometheus_stack() {
    print_header "Installing Prometheus Stack"
    
    print_status "Installing Prometheus Stack with Grafana"
    
    # Create values file for Prometheus Stack
    cat > prometheus-values.yaml <<EOF
# Prometheus Stack Configuration
grafana:
  enabled: true
  adminPassword: "admin123"
  persistence:
    enabled: true
    size: 10Gi
  service:
    type: LoadBalancer
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster:
        gnetId: 315
        revision: 3
        datasource: Prometheus
      kubernetes-pods:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      kubernetes-services:
        gnetId: 6418
        revision: 1
        datasource: Prometheus
      kubernetes-deployment:
        gnetId: 6419
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 22
        datasource: Prometheus
      prometheus:
        gnetId: 3662
        revision: 1
        datasource: Prometheus
      grafana:
        gnetId: 4701
        revision: 1
        datasource: Prometheus

prometheus:
  enabled: true
  prometheusSpec:
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ebs-sc
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    resources:
      requests:
        memory: 512Mi
        cpu: 250m
      limits:
        memory: 1Gi
        cpu: 500m

alertmanager:
  enabled: true
  alertmanagerSpec:
    retention: 120h
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: ebs-sc
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

kube-state-metrics:
  enabled: true

node-exporter:
  enabled: true

kubelet:
  enabled: true

EOF
    
    # Install Prometheus Stack
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace $NAMESPACE \
        --version $PROMETHEUS_STACK_VERSION \
        --values prometheus-values.yaml \
        --wait \
        --timeout 10m
    
    print_status "Prometheus Stack installed successfully"
}

# Install additional monitoring tools
install_additional_monitoring() {
    print_header "Installing Additional Monitoring Tools"
    
    # Install Metrics Server (if not already installed)
    print_status "Installing Metrics Server"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Install Kubernetes Dashboard
    print_status "Installing Kubernetes Dashboard"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Create dashboard admin user
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
    
    print_status "Additional monitoring tools installed"
}

# Create custom dashboards
create_custom_dashboards() {
    print_header "Creating Custom Dashboards"
    
    # Create ConfigMap for custom dashboards
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboards
  namespace: $NAMESPACE
data:
  stylehub-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "StyleHub Overview",
        "tags": ["stylehub", "overview"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Pod Status",
            "type": "stat",
            "targets": [
              {
                "expr": "count(kube_pod_info{namespace=\"stylehub\"})",
                "legendFormat": "Total Pods"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {
                  "mode": "palette-classic"
                }
              }
            }
          },
          {
            "id": 2,
            "title": "CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"stylehub\"}[5m])) by (pod)",
                "legendFormat": "{{pod}}"
              }
            ]
          },
          {
            "id": 3,
            "title": "Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(container_memory_usage_bytes{namespace=\"stylehub\"}) by (pod)",
                "legendFormat": "{{pod}}"
              }
            ]
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF
    
    print_status "Custom dashboards created"
}

# Create ServiceMonitor for StyleHub
create_servicemonitor() {
    print_header "Creating ServiceMonitor for StyleHub"
    
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: stylehub-monitor
  namespace: $NAMESPACE
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: stylehub-ui
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: stylehub-backend-monitor
  namespace: $NAMESPACE
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      component: backend
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF
    
    print_status "ServiceMonitor created for StyleHub"
}

# Create PrometheusRules for alerts
create_prometheusrules() {
    print_header "Creating PrometheusRules for Alerts"
    
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: stylehub-alerts
  namespace: $NAMESPACE
  labels:
    release: prometheus
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: stylehub.rules
    rules:
    - alert: PodDown
      expr: up{namespace="stylehub"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} is down"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been down for more than 1 minute"
    
    - alert: HighCPUUsage
      expr: sum(rate(container_cpu_usage_seconds_total{namespace="stylehub"}[5m])) by (pod) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.pod }}"
        description: "Pod {{ $labels.pod }} is using more than 80% CPU for 5 minutes"
    
    - alert: HighMemoryUsage
      expr: sum(container_memory_usage_bytes{namespace="stylehub"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="stylehub"}) by (pod) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.pod }}"
        description: "Pod {{ $labels.pod }} is using more than 80% memory for 5 minutes"
    
    - alert: PodRestarting
      expr: increase(kube_pod_container_status_restarts_total{namespace="stylehub"}[15m]) > 0
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is restarting"
        description: "Pod {{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes"
EOF
    
    print_status "PrometheusRules created"
}

# Show access information
show_access_info() {
    print_header "Monitoring Access Information"
    
    # Get Grafana Load Balancer
    GRAFANA_SERVICE=$(kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$GRAFANA_SERVICE" ]; then
        echo -e "${GREEN}Grafana Load Balancer:${NC}"
        echo -e "${BLUE}URL:${NC} http://$GRAFANA_SERVICE"
        echo -e "${BLUE}Username:${NC} admin"
        echo -e "${BLUE}Password:${NC} admin123"
        echo ""
    else
        print_warning "Grafana Load Balancer not available yet. Using port forwarding..."
        echo ""
    fi
    
    # Port forwarding options
    echo -e "${GREEN}Development Access (Port Forwarding):${NC}"
    echo -e "${BLUE}Grafana:${NC} kubectl port-forward svc/prometheus-grafana 3000:80 -n $NAMESPACE"
    echo -e "${BLUE}URL:${NC} http://localhost:3000"
    echo -e "${BLUE}Username:${NC} admin"
    echo -e "${BLUE}Password:${NC} admin123"
    echo ""
    
    echo -e "${BLUE}Prometheus:${NC} kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n $NAMESPACE"
    echo -e "${BLUE}URL:${NC} http://localhost:9090"
    echo ""
    
    echo -e "${BLUE}AlertManager:${NC} kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n $NAMESPACE"
    echo -e "${BLUE}URL:${NC} http://localhost:9093"
    echo ""
    
    echo -e "${BLUE}Kubernetes Dashboard:${NC} kubectl port-forward svc/kubernetes-dashboard 8443:443 -n kubernetes-dashboard"
    echo -e "${BLUE}URL:${NC} https://localhost:8443"
    echo ""
    
    # Get dashboard token
    DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user --duration=8760h)
    echo -e "${BLUE}Dashboard Token:${NC} $DASHBOARD_TOKEN"
    echo ""
}

# Show useful commands
show_useful_commands() {
    print_header "Useful Monitoring Commands"
    
    echo -e "${BLUE}Check monitoring pods:${NC}"
    echo "kubectl get pods -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}View Grafana logs:${NC}"
    echo "kubectl logs -f deployment/prometheus-grafana -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}View Prometheus logs:${NC}"
    echo "kubectl logs -f statefulset/prometheus-kube-prometheus-prometheus -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}Check ServiceMonitors:${NC}"
    echo "kubectl get servicemonitors -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}Check PrometheusRules:${NC}"
    echo "kubectl get prometheusrules -n $NAMESPACE"
    echo ""
    
    echo -e "${BLUE}View metrics:${NC}"
    echo "kubectl top pods -n stylehub"
    echo "kubectl top nodes"
    echo ""
    
    echo -e "${BLUE}Check alerts:${NC}"
    echo "kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n $NAMESPACE"
    echo "# Then visit http://localhost:9093"
    echo ""
}

# Main function
main() {
    print_header "Kubernetes Monitoring Setup"
    
    check_prerequisites
    add_helm_repos
    create_namespace
    install_prometheus_stack
    install_additional_monitoring
    create_custom_dashboards
    create_servicemonitor
    create_prometheusrules
    show_access_info
    show_useful_commands
    
    print_status "Monitoring setup completed successfully!"
    echo ""
    print_warning "Remember to:"
    echo "1. Change default passwords in production"
    echo "2. Configure persistent storage for production"
    echo "3. Set up alert notifications"
    echo "4. Configure custom dashboards for your applications"
}

# Run main function
main "$@"
