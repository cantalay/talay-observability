# talay-observability

Metrics, log, trace ve görselleştirmeyi tek Terraform state altında birleştirir; içerideki bileşenler yine ayrı Helm release'tir:

```text
Applications --OTLP--> OpenTelemetry Collector --traces--> Tempo
       |                       |              --metrics--> Prometheus
       +--stdout--> Alloy -----+-----logs----------------> Loki
                                                        \-> Grafana
```

- Prometheus + Alertmanager: `kube-prometheus-stack 88.6.3`
- Logs: `Loki 18.11.7` (single binary) + `Alloy 1.12.1`
- Traces: `Tempo 2.3.0` (single binary) + `OpenTelemetry Collector 0.172.0`
- UI ve sinyal korelasyonu: `Grafana 13.1.0`

Promtail 2026-03-02'de EOL olduğu için kullanılmaz. Grafana, Loki ve Tempo deprecated eski Grafana Helm deposundan değil aktif Grafana Community deposundan kurulur.

## Vault alanları

```text
kv/platform/grafana:      admin-user, admin-password
kv/platform/alertmanager: config   # tam alertmanager.yaml içeriği
```

Java/Node uygulamaları OTLP HTTP için `http://otel-collector.monitoring.svc.cluster.local:4318` kullanır. Container stdout/stderr logları Alloy tarafından Loki'ye taşınır. Browser/mobil için public OTLP ingress varsayılan olarak kapalıdır; açılacaksa authentication, CORS ve rate limiting eklenmelidir.

Bu profil tek sunucu için local persistent volume kullanır. Loki/Tempo/Prometheus verileri sunucu kaybına karşı dayanıklı değildir; ölçek büyüdüğünde object storage ve çok-node topolojisine taşınmalıdır.
