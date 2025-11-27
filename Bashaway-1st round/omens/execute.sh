#!/bin/bash
#!/bin/bash
mkdir -p out

cat > out/prometheus.yml << 'PROM'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
PROM

cat > out/datasource.yml << 'DS'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
DS

cat > out/alerts.yml << 'ALERTS'
groups:
  - name: system_alerts
    interval: 30s
    rules:
      - alert: HighCPU
        expr: 'node_cpu_seconds_total > 0.8'
        for: 5m
        annotations:
          summary: "High CPU usage detected"
      
      - alert: HighMemory
        expr: 'node_memory_MemAvailable_bytes < 1000000000'
        for: 5m
        annotations:
          summary: "High memory usage detected"
      
      - alert: HighDiskIO
        expr: 'node_disk_io_time_seconds_total > 0.9'
        for: 5m
        annotations:
          summary: "High disk I/O detected"
      
      - alert: ServiceDown
        expr: 'up == 0'
        for: 1m
        annotations:
          summary: "Service is down"
ALERTS

cat > out/dashboard.json << 'DASH'
{
  "dashboard": {
    "title": "System Monitoring",
    "tags": ["monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "node_cpu_seconds_total"
          }
        ]
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "node_memory_MemAvailable_bytes"
          }
        ]
      },
      {
        "id": 3,
        "title": "Disk I/O",
        "type": "graph",
        "targets": [
          {
            "expr": "node_disk_io_time_seconds_total"
          }
        ]
      },
      {
        "id": 4,
        "title": "Service Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up"
          }
        ]
      }
    ]
  }
}
DASH
