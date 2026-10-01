resource "helm_release" "loki" {
  name       = "loki"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "loki"
  version    = "18.11.7"

  atomic  = true
  wait    = true
  timeout = 1200

  values = [templatefile("${path.module}/values-loki.yaml.tftpl", {
    storage_class    = var.storage_class
    storage_size     = var.storage_size
    retention_period = var.retention_period
  })]
}
