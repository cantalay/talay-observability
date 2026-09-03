variable "kubeconfig_path" {
  type    = string
  default = "../talay-cluster/stacks/bootstrap/kubeconfig.yaml"
}

variable "grafana_domain" {
  type = string
}

variable "storage_class" {
  type    = string
  default = "local-path"
}

variable "prometheus_storage_size" {
  type    = string
  default = "20Gi"
}

variable "alertmanager_storage_size" {
  type    = string
  default = "2Gi"
}

variable "loki_storage_size" {
  type    = string
  default = "20Gi"
}

variable "tempo_storage_size" {
  type    = string
  default = "10Gi"
}

variable "grafana_storage_size" {
  type    = string
  default = "5Gi"
}

variable "metrics_retention" {
  type    = string
  default = "15d"
}

variable "logs_retention" {
  type    = string
  default = "168h"
}

variable "traces_retention" {
  type    = string
  default = "168h"
}

variable "vault_grafana_key" {
  type    = string
  default = "platform/grafana"
}

variable "vault_alertmanager_key" {
  type    = string
  default = "platform/alertmanager"
}

variable "otel_public_ingress_enabled" {
  type    = bool
  default = false
}

variable "otel_domain" {
  type     = string
  default  = null
  nullable = true

  validation {
    condition     = !var.otel_public_ingress_enabled || var.otel_domain != null
    error_message = "Public OTLP ingress açıldığında otel_domain zorunludur."
  }
}
