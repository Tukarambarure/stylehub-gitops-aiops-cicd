# Kubernetes Monitoring Quick Reference

## 🚀 Quick Setup

```bash
# Install monitoring stack
chmod +x setup-monitoring.sh
./setup-monitoring.sh

# Access Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# http://localhost:3000 (admin/admin123)
```

## 🌐 Access Methods

### Grafana (Main Dashboard)
```bash
# Port forwarding
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# http://localhost:3000

# Load balancer
kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### Prometheus (Metrics)
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# http://localhost:9090
```

### AlertManager (Alerts)
```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring
# http://localhost:9093
```

### Kubernetes Dashboard
```bash
kubectl port-forward svc/kubernetes-dashboard 8443:443 -n kubernetes-dashboard
# https://localhost:8443
# Token: kubectl -n kubernetes-dashboard create token admin-user
```

## 📊 Available Dashboards

1. **Kubernetes Cluster Overview** - Cluster-wide metrics
2. **Kubernetes Pods Detail** - Detailed pod metrics
3. **StyleHub Application Monitoring** - Application-specific metrics
4. **Kubernetes Services** - Service metrics
5. **Kubernetes Deployments** - Deployment metrics

## 🔍 Key Prometheus Queries

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
# Node CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
100 - ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100)

# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod)

# Pod memory usage
sum(container_memory_usage_bytes{container!=""}) by (pod)
```

### StyleHub Specific
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

## 🛠️ Useful Commands

### Check Monitoring Status
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check ServiceMonitors
kubectl get servicemonitors -n monitoring

# Check PrometheusRules
kubectl get prometheusrules -n monitoring

# Check metrics server
kubectl get pods -n kube-system | grep metrics-server
```

### View Logs
```bash
# Grafana logs
kubectl logs -f deployment/prometheus-grafana -n monitoring

# Prometheus logs
kubectl logs -f statefulset/prometheus-kube-prometheus-prometheus -n monitoring

# AlertManager logs
kubectl logs -f statefulset/prometheus-kube-prometheus-alertmanager -n monitoring
```

### Check Metrics
```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -n stylehub

# All pods metrics
kubectl top pods --all-namespaces
```

### Check Alerts
```bash
# View active alerts
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring
# Then visit http://localhost:9093

# Check alert rules
kubectl get prometheusrules -n monitoring -o yaml
```

## 🚨 Common Alerts

### Critical Alerts
- **PodDown**: Pod is not running
- **HighCPUUsage**: CPU usage > 80%
- **HighMemoryUsage**: Memory usage > 80%
- **PodRestarting**: Pod is restarting frequently

### Alert Queries
```promql
# Pod down
up{namespace="stylehub"} == 0

# High CPU
sum(rate(container_cpu_usage_seconds_total{namespace="stylehub"}[5m])) by (pod) > 0.8

# High memory
sum(container_memory_usage_bytes{namespace="stylehub"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="stylehub"}) by (pod) > 0.8

# Pod restarts
increase(kube_pod_container_status_restarts_total{namespace="stylehub"}[15m]) > 0
```

## 📈 Creating Custom Dashboards

### Via Grafana UI
1. Go to Grafana → Dashboards → New Dashboard
2. Add panels with Prometheus queries
3. Configure visualization and layout
4. Save dashboard

### Via ConfigMap
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
        "title": "My Dashboard",
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

### Prometheus Values
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

grafana:
  adminPassword: "your-secure-password"
  persistence:
    enabled: true
    size: 10Gi
  service:
    type: LoadBalancer
```

### ServiceMonitor Example
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-service-monitor
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
```

## 🔍 Troubleshooting

### Common Issues

#### No Metrics Available
```bash
# Check metrics server
kubectl get pods -n kube-system | grep metrics-server

# Check node metrics
kubectl top nodes

# Check pod metrics
kubectl top pods -n stylehub
```

#### Prometheus Not Scraping
```bash
# Check ServiceMonitor
kubectl get servicemonitors -n monitoring

# Check Prometheus targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
# Then visit http://localhost:9090/targets
```

#### Grafana Not Loading
```bash
# Check Grafana logs
kubectl logs -f deployment/prometheus-grafana -n monitoring

# Check ConfigMap
kubectl get configmaps -n monitoring -l grafana_dashboard=1
```

### Debugging Commands
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check monitoring services
kubectl get svc -n monitoring

# Check monitoring configmaps
kubectl get configmaps -n monitoring

# Check monitoring secrets
kubectl get secrets -n monitoring
```

## 📋 Useful Aliases

```bash
# Add to your .bashrc or .zshrc
alias grafana='kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring'
alias prometheus='kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring'
alias alertmanager='kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring'
alias k8s-dashboard='kubectl port-forward svc/kubernetes-dashboard 8443:443 -n kubernetes-dashboard'
alias monitoring-pods='kubectl get pods -n monitoring'
alias monitoring-logs='kubectl logs -f deployment/prometheus-grafana -n monitoring'
```

## 🎯 Best Practices

### 1. Resource Management
- Set appropriate resource limits
- Use persistent storage
- Monitor storage usage

### 2. Security
- Change default passwords
- Use RBAC
- Enable TLS in production

### 3. Performance
- Configure retention periods
- Use efficient queries
- Set proper alert thresholds

### 4. Maintenance
- Backup dashboards
- Monitor storage usage
- Update regularly

---

**Quick Tips:**
- Use `kubectl top` for quick resource usage
- Use Prometheus UI for query testing
- Use Grafana for visualization
- Set up alerts for critical metrics
- Monitor the monitoring stack itself
