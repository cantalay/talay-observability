resource "helm_release" "secrets" {
  name      = "observability-secrets"
  namespace = "monitoring"
  chart     = var.chart_path

  atomic  = true
  wait    = true
  timeout = 300

  values = [yamlencode({
    refreshInterval = "1h"
    grafana         = { remoteKey = var.vault_grafana_key }
    alertmanager    = { remoteKey = var.vault_alertmanager_key }
  })]
}
