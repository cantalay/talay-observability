resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "88.6.3"

  atomic  = true
  wait    = true
  timeout = 1200

  values = [templatefile("${path.module}/values-prometheus.yaml.tftpl", {
    storage_class             = var.storage_class
    prometheus_storage_size   = var.prometheus_storage_size
    alertmanager_storage_size = var.alertmanager_storage_size
    metrics_retention         = var.metrics_retention
  })]
}
