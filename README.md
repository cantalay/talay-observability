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

Root stack yalnızca kompozisyondur. Her release ve values dosyası `modules/{prometheus,loki,tempo,alloy,otel-collector,grafana}` altında; ortak secret ve monitor kaynakları ise `modules/observability-secrets` ile `modules/platform-monitors` altında tutulur.

Promtail 2026-03-02'de EOL olduğu için kullanılmaz. Grafana, Loki ve Tempo deprecated eski Grafana Helm deposundan değil aktif Grafana Community deposundan kurulur.

## Gözlem hattı alarmları

`charts/platform-monitors/templates/observability-pipeline-rules.yaml` hattın kendisini izler:
- **DaemonSet kapsamı:** monitoring DaemonSet'lerinin her düğümde çalışması.
- **Log hattı:** Alloy ayakta mı, Loki satır alıyor mu, düşen satır var mı.
- **Diğer hatlar:** node-exporter; OTel Collector ve Tempo.

2026-10-11'de Alloy ve node-exporter, elle eklenmiş bir `nodeSelector` yüzünden haftalarca 0 pod'da kaldı. İstenen pod
sayısı 0 olduğu için varsayılan kurallar tetiklenmedi. Elle yapılan bu değişiklik geri alındı.

Kural: bir bileşeni geçici kapatmak gerekirse bunu bu repoda, values üzerinden yap.

k3s kube-proxy metriği yayınlamadığı için `kubeProxy.enabled: false` ayarlı; aksi hâlde `KubeProxyDown` sürekli çalar.

## Vault alanları

```text
kv/platform/grafana:      admin-user, admin-password
kv/platform/alertmanager: config   # tam alertmanager.yaml içeriği
```

Java/Node uygulamaları OTLP HTTP için `http://otel-collector.monitoring.svc.cluster.local:4318` kullanır. Container stdout/stderr logları Alloy tarafından Loki'ye taşınır. Browser/mobil için public OTLP ingress varsayılan olarak kapalıdır; açılacaksa authentication, CORS ve rate limiting eklenmelidir.

Bu profil tek sunucu için local persistent volume kullanır. Loki/Tempo/Prometheus verileri sunucu kaybına karşı dayanıklı değildir; ölçek büyüdüğünde object storage ve çok-node topolojisine taşınmalıdır.
