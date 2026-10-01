resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "grafana"
  version    = "13.1.0"

  atomic  = true
  wait    = true
  timeout = 900

  values = [templatefile("${path.module}/values-grafana.yaml.tftpl", {
    grafana_domain = var.domain
    storage_class  = var.storage_class
    storage_size   = var.storage_size
  })]
}
