resource "helm_release" "alloy" {
  name       = "alloy"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.12.1"

  atomic  = true
  wait    = true
  timeout = 900

  values = [file("${path.module}/values-alloy.yaml")]
}
