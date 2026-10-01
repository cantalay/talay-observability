resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  namespace  = "monitoring"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.172.0"

  atomic  = true
  wait    = true
  timeout = 900

  values = [
    file("${path.module}/values-otel-collector.yaml"),
    yamlencode({
      ingress = {
        enabled          = var.public_ingress_enabled
        ingressClassName = "traefik"
        annotations      = { "cert-manager.io/cluster-issuer" = "letsencrypt" }
        hosts = var.public_ingress_enabled ? [{
          host  = var.domain
          paths = [{ path = "/", pathType = "Prefix", port = 4318 }]
        }] : []
        tls = var.public_ingress_enabled ? [{
          secretName = "otel-collector-tls"
          hosts      = [var.domain]
        }] : []
      }
    }),
  ]
}
