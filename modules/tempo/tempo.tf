resource "helm_release" "tempo" {
  name       = "tempo"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "tempo"
  version    = "2.3.0"

  atomic  = true
  wait    = true
  timeout = 900

  values = [templatefile("${path.module}/values-tempo.yaml.tftpl", {
    storage_class = var.storage_class
    storage_size  = var.storage_size
    retention     = var.retention
  })]
}
