module "observability_secrets" {
  source = "./modules/observability-secrets"

  chart_path             = "${path.root}/charts/observability-secrets"
  vault_grafana_key      = var.vault_grafana_key
  vault_alertmanager_key = var.vault_alertmanager_key
}

module "prometheus" {
  source = "./modules/prometheus"

  storage_class             = var.storage_class
  prometheus_storage_size   = var.prometheus_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  metrics_retention         = var.metrics_retention

  depends_on = [module.observability_secrets]
}

module "platform_monitors" {
  source = "./modules/platform-monitors"

  chart_path = "${path.root}/charts/platform-monitors"

  depends_on = [module.prometheus]
}

module "loki" {
  source = "./modules/loki"

  storage_class    = var.storage_class
  storage_size     = var.loki_storage_size
  retention_period = var.logs_retention

  depends_on = [module.prometheus]
}

module "tempo" {
  source = "./modules/tempo"

  storage_class = var.storage_class
  storage_size  = var.tempo_storage_size
  retention     = var.traces_retention

  depends_on = [module.prometheus]
}

module "alloy" {
  source = "./modules/alloy"

  depends_on = [module.loki]
}

module "otel_collector" {
  source = "./modules/otel-collector"

  public_ingress_enabled = var.otel_public_ingress_enabled
  domain                 = var.otel_domain

  depends_on = [module.prometheus, module.loki, module.tempo]
}

module "grafana" {
  source = "./modules/grafana"

  domain        = var.grafana_domain
  storage_class = var.storage_class
  storage_size  = var.grafana_storage_size

  depends_on = [
    module.observability_secrets,
    module.prometheus,
    module.loki,
    module.tempo,
  ]
}

moved {
  from = helm_release.secrets
  to   = module.observability_secrets.helm_release.secrets
}

moved {
  from = helm_release.prometheus
  to   = module.prometheus.helm_release.prometheus
}

moved {
  from = helm_release.platform_monitors
  to   = module.platform_monitors.helm_release.platform_monitors
}

moved {
  from = helm_release.loki
  to   = module.loki.helm_release.loki
}

moved {
  from = helm_release.tempo
  to   = module.tempo.helm_release.tempo
}

moved {
  from = helm_release.alloy
  to   = module.alloy.helm_release.alloy
}

moved {
  from = helm_release.otel_collector
  to   = module.otel_collector.helm_release.otel_collector
}

moved {
  from = helm_release.grafana
  to   = module.grafana.helm_release.grafana
}
