resource "helm_release" "secrets" {
  name      = "observability-secrets"
  namespace = "monitoring"
  chart     = "${path.module}/charts/observability-secrets"

  atomic  = true
  wait    = true
  timeout = 300

  values = [yamlencode({
    refreshInterval = "1h"
    grafana = {
      remoteKey = var.vault_grafana_key
    }
    alertmanager = {
      remoteKey = var.vault_alertmanager_key
    }
  })]
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "88.6.3"

  atomic  = true
  wait    = true
  timeout = 1200

  values = [templatefile("${path.module}/values/prometheus.yaml.tftpl", {
    storage_class             = var.storage_class
    prometheus_storage_size   = var.prometheus_storage_size
    alertmanager_storage_size = var.alertmanager_storage_size
    metrics_retention         = var.metrics_retention
  })]

  depends_on = [helm_release.secrets]
}

resource "helm_release" "platform_monitors" {
  name      = "platform-monitors"
  namespace = "monitoring"
  chart     = "${path.module}/charts/platform-monitors"

  atomic  = true
  wait    = true
  timeout = 300

  depends_on = [helm_release.prometheus]
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "loki"
  version    = "18.11.7"

  atomic  = true
  wait    = true
  timeout = 1200

  values = [templatefile("${path.module}/values/loki.yaml.tftpl", {
    storage_class    = var.storage_class
    storage_size     = var.loki_storage_size
    retention_period = var.logs_retention
  })]

  depends_on = [helm_release.prometheus]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "tempo"
  version    = "2.3.0"

  atomic  = true
  wait    = true
  timeout = 900

  values = [templatefile("${path.module}/values/tempo.yaml.tftpl", {
    storage_class = var.storage_class
    storage_size  = var.tempo_storage_size
    retention     = var.traces_retention
  })]

  depends_on = [helm_release.prometheus]
}

resource "helm_release" "alloy" {
  name       = "alloy"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.12.1"

  atomic  = true
  wait    = true
  timeout = 900

  values = [file("${path.module}/values/alloy.yaml")]

  depends_on = [helm_release.loki]
}

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
    file("${path.module}/values/otel-collector.yaml"),
    yamlencode({
      ingress = {
        enabled          = var.otel_public_ingress_enabled
        ingressClassName = "traefik"
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt"
        }
        hosts = var.otel_public_ingress_enabled ? [{
          host = var.otel_domain
          paths = [{
            path     = "/"
            pathType = "Prefix"
            port     = 4318
          }]
        }] : []
        tls = var.otel_public_ingress_enabled ? [{
          secretName = "otel-collector-tls"
          hosts      = [var.otel_domain]
        }] : []
      }
    }),
  ]

  depends_on = [helm_release.prometheus, helm_release.loki, helm_release.tempo]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana-community.github.io/helm-charts"
  chart      = "grafana"
  version    = "13.1.0"

  atomic  = true
  wait    = true
  timeout = 900

  values = [templatefile("${path.module}/values/grafana.yaml.tftpl", {
    grafana_domain = var.grafana_domain
    storage_class  = var.storage_class
    storage_size   = var.grafana_storage_size
  })]

  depends_on = [
    helm_release.secrets,
    helm_release.prometheus,
    helm_release.loki,
    helm_release.tempo,
  ]
}
