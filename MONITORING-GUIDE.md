# Kubernetes Monitoring with Prometheus & Grafana

This guide explains how to set up comprehensive monitoring for your Kubernetes cluster using Prometheus and Grafana to monitor all K8s resources, pods, and applications.

## 🚀 Quick Start

### 1. Install Monitoring Stack

```bash
# Make script executable
chmod +x setup-monitoring.sh

# Run the complete monitoring setup
./setup-monitoring.sh
```

### 2. Access Grafana

```bash
# Port forward Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

# Access at: http://localhost:3000
# Username: admin
# Password: admin123
```

## 🔧 Manual Installation

### Step 1: Install Prometheus Stack

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml
```

### Step 2: Apply Custom Dashboards

```bash
# Apply custom dashboards
kubectl apply -f monitoring/grafana-dashboards.yaml
```

## 🌐 Accessing Monitoring Tools

### Grafana (Main Dashboard)

**Port Forwarding (Development):**
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Access: http://localhost:3000
# Username: admin
# Password: admin123
```

**Load Balancer (Production):**
```bash
# Get Grafana Load Balancer DNS
kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
# Access: http://<dns-name>
```

### Prometheus (Metrics Database)

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Access: http://localhost:9090
```

### AlertManager (Alerts)

```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring
# Access: http://localhost:9093
```

### Kubernetes Dashboard

```bash
kubectl port-forward svc/kubernetes-dashboard 8443:443 -n kubernetes-dashboard
# Access: https://localhost:8443
# Token: (get from kubectl -n kubernetes-dashboard create token admin-user)
```

## 📊 Available Dashboards

### 1. Kubernetes Cluster Overview
- **Cluster Nodes**: Total number of nodes
- **Total Pods**: All pods across namespaces
- **Running Pods**: Currently running pods
- **Failed Pods**: Failed pods
- **Node CPU Usage**: CPU utilization per node
- **Node Memory Usage**: Memory utilization per node

### 2. Kubernetes Pods Detail
- **Pod Status by Namespace**: Pie chart of pod phases
- **Pod Restarts**: Restart count per pod
- **Container CPU Usage**: CPU usage per container
- **Container Memory Usage**: Memory usage per container
- **Pod Network I/O**: Network traffic per pod
- **Pod Disk I/O**: Disk I/O per pod

### 3. StyleHub Application Monitoring
- **StyleHub Pod Status**: Pod counts by status
- **StyleHub Services**: Service information
- **StyleHub Deployments**: Deployment status
- **StyleHub HPA Status**: Horizontal Pod Autoscaler status
- **StyleHub Pod CPU Usage**: CPU usage for StyleHub pods
- **StyleHub Pod Memory Usage**: Memory usage for StyleHub pods
- **StyleHub Pod Restarts**: Restart count for StyleHub pods
- **StyleHub Network Traffic**: Network traffic for StyleHub pods

### 4. Kubernetes Services
- **Services by Namespace**: Service distribution
- **Service Endpoints**: Endpoint availability
- **Service Ports**: Port configuration

### 5. Kubernetes Deployments
- **Deployment Status**: Replica availability
- **Deployment Conditions**: Health conditions
- **Deployment Update Status**: Update progress

## 🔍 Key Metrics to Monitor

### Cluster Level Metrics

#### Node Metrics
```promql
# Node CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

# Node disk usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

#### Pod Metrics
```promql
# Pod status
count by (namespace, phase) (kube_pod_status_phase)

# Pod restarts
increase(kube_pod_container_status_restarts_total[1h])

# Container CPU usage
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod, container)

# Container memory usage
sum(container_memory_usage_bytes{container!=""}) by (pod, container)
```

### Application Level Metrics

#### StyleHub Specific
```promql
# StyleHub pod count
count(kube_pod_info{namespace="stylehub"})

# StyleHub running pods
count(kube_pod_status_phase{namespace="stylehub", phase="Running"})

# StyleHub CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="stylehub", container!=""}[5m])) by (pod)

# StyleHub memory usage
sum(container_memory_usage_bytes{namespace="stylehub", container!=""}) by (pod)
```

## 🚨 Alerting Rules

### Critical Alerts

#### Pod Down
```yaml
- alert: PodDown
  expr: up{namespace="stylehub"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Pod {{ $labels.pod }} is down"
```

#### High CPU Usage
```yaml
- alert: HighCPUUsage
  expr: sum(rate(container_cpu_usage_seconds_total{namespace="stylehub"}[5m])) by (pod) > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High CPU usage on {{ $labels.pod }}"
```

#### High Memory Usage
```yaml
- alert: HighMemoryUsage
  expr: sum(container_memory_usage_bytes{namespace="stylehub"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="stylehub"}) by (pod) > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High memory usage on {{ $labels.pod }}"
```

## 🛠️ Useful Prometheus Queries

### Cluster Health
```promql
# Total nodes
count(kube_node_info)

# Total pods
count(kube_pod_info)

# Running pods
count(kube_pod_status_phase{phase="Running"})

# Failed pods
count(kube_pod_status_phase{phase="Failed"})
```

### Resource Usage
```promql
# Top CPU consuming pods
topk(10, sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod))

# Top memory consuming pods
topk(10, sum(container_memory_usage_bytes{container!=""}) by (pod))

# Network traffic
sum(rate(container_network_receive_bytes_total{container!=""}[5m])) by (pod)
sum(rate(container_network_transmit_bytes_total{container!=""}[5m])) by (pod)
```

### Application Metrics
```promql
# StyleHub pod status
count by (phase) (kube_pod_status_phase{namespace="stylehub"})

# StyleHub service endpoints
kube_endpoint_address_available{namespace="stylehub"}

# StyleHub deployment replicas
kube_deployment_status_replicas_available{namespace="stylehub"}
```

## 📈 Creating Custom Dashboards

### 1. Via Grafana UI
1. Go to Grafana → Dashboards → New Dashboard
2. Add panels with Prometheus queries
3. Configure visualization and layout
4. Save dashboard

### 2. Via ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  my-dashboard.json: |
    {
      "dashboard": {
        "title": "My Custom Dashboard",
        "panels": [
          {
            "title": "My Panel",
            "type": "graph",
            "targets": [
              {
                "expr": "your_prometheus_query_here"
              }
            ]
          }
        ]
      }
    }
```

## 🔧 Configuration

### Prometheus Configuration
```yaml
# prometheus-values.yaml
prometheus:
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
```

### Grafana Configuration
```yaml
grafana:
  adminPassword: "your-secure-password"
  persistence:
    enabled: true
    size: 10Gi
  service:
    type: LoadBalancer
```

### AlertManager Configuration
```yaml
alertmanager:
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
```

## 🔍 Troubleshooting

### Common Issues

#### Prometheus Not Scraping
```bash
# Check ServiceMonitor
kubectl get servicemonitors -n monitoring

# Check Prometheus targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Then visit http://localhost:9090/targets
```

#### Grafana Not Loading Dashboards
```bash
# Check Grafana logs
kubectl logs -f deployment/prometheus-grafana -n monitoring

# Check ConfigMap
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```

#### No Metrics Available
```bash
# Check if metrics server is running
kubectl get pods -n kube-system | grep metrics-server

# Check node metrics
kubectl top nodes

# Check pod metrics
kubectl top pods -n stylehub
```

### Debugging Commands

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check Prometheus logs
kubectl logs -f statefulset/prometheus-kube-prometheus-prometheus -n monitoring

# Check Grafana logs
kubectl logs -f deployment/prometheus-grafana -n monitoring

# Check AlertManager logs
kubectl logs -f statefulset/prometheus-kube-prometheus-alertmanager -n monitoring

# Check ServiceMonitors
kubectl get servicemonitors -n monitoring

# Check PrometheusRules
kubectl get prometheusrules -n monitoring
```

## 🎯 Best Practices

### 1. Resource Management
- Set appropriate resource limits for Prometheus and Grafana
- Use persistent storage for data retention
- Monitor storage usage and set up alerts

### 2. Security
- Change default passwords
- Use RBAC for access control
- Enable TLS for production deployments
- Regularly update monitoring stack versions

### 3. Performance
- Configure appropriate retention periods
- Use efficient PromQL queries
- Set up proper alerting thresholds
- Monitor monitoring stack performance

### 4. Maintenance
- Regularly backup Grafana dashboards
- Monitor Prometheus storage usage
- Update dashboards and alerts as needed
- Review and optimize queries

## 📞 Support

For issues and questions:

1. [Prometheus Documentation](https://prometheus.io/docs/)
2. [Grafana Documentation](https://grafana.com/docs/)
3. [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

---

**Happy Monitoring! 📊**
