output "grafana_url" {
  value = "https://${var.grafana_domain}"
}

output "otlp_endpoints" {
  value = {
    grpc = "http://otel-collector.monitoring.svc.cluster.local:4317"
    http = "http://otel-collector.monitoring.svc.cluster.local:4318"
  }
}

output "signal_backends" {
  value = {
    prometheus = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
    loki       = "http://loki-gateway.monitoring.svc.cluster.local"
    tempo      = "http://tempo.monitoring.svc.cluster.local:3200"
  }
}
