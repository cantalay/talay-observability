resource "helm_release" "platform_monitors" {
  name      = "platform-monitors"
  namespace = "monitoring"
  chart     = var.chart_path

  atomic  = true
  wait    = true
  timeout = 300
}
