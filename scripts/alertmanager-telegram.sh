#!/usr/bin/env bash
# Alertmanager alarmlarını Telegram'a bağlar; aynı botu sunucudaki talay-backup ve dış gözcü
# talay-watch bildirimlerine de verir. Tekrar çalıştırılabilir.
#
# Ön koşul:
#   1. @BotFather ile bot oluştur, botla özel sohbette /start yaz (chat id buradan bulunur).
#   2. export VAULT_ADDR=https://vault.cantalay.com && vault login -method=oidc
#   3. vault kv patch kv/platform/telegram bot-token=-   (token'ı stdin'e yapıştır; yol yoksa kv put)
#
# Kullanım: scripts/alertmanager-telegram.sh
# Token hiçbir adımda ekrana ya da komut satırına yazılmaz (stdin / ortam değişkeni ile taşınır).
set -euo pipefail

APP_HOST=${TALAY_HOST:-152.53.66.101}
WATCH_HOST=${TALAY_WATCH_HOST:-45.87.80.10}
export VAULT_ADDR=${VAULT_ADDR:-https://vault.cantalay.com}

die() { echo "HATA: $*" >&2; exit 1; }
for c in vault jq curl ssh; do command -v "$c" >/dev/null || die "$c yok"; done
vault token lookup >/dev/null 2>&1 || die "Vault oturumu yok: vault login -method=oidc"

TELEGRAM_BOT_TOKEN=$(vault kv get -field=bot-token kv/platform/telegram 2>/dev/null) \
  || die "kv/platform/telegram bot-token yok (ön koşul 3)"
export TELEGRAM_BOT_TOKEN

tg() { curl -fsS -m 20 --config - <<<"url = \"https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/$1\"" "${@:2}"; }

bot=$(tg getMe | jq -r '.result.username') || die "token geçersiz (getMe)"
echo "bot: @$bot"

chat_id=$(vault kv get -field=chat-id kv/platform/telegram 2>/dev/null || true)
if [ -z "$chat_id" ]; then
  chat_id=$(tg getUpdates | jq -r '[.result[] | (.message // .my_chat_member) | .chat | select(.type == "private") | .id] | last // empty')
  [ -n "$chat_id" ] || die "@$bot ile özel sohbette /start yaz, sonra tekrar çalıştır"
  vault kv patch kv/platform/telegram chat-id="$chat_id" >/dev/null
fi
echo "chat id: $chat_id"

# 1) Alertmanager yapılandırması (kv/platform/alertmanager#config, ExternalSecret alertmanager-config)
config=$(cat <<EOF
global:
  resolve_timeout: 5m
route:
  receiver: telegram
  group_by: [alertname, namespace]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  routes:
    - receiver: "null"
      matchers: ['alertname = "Watchdog"']
    - receiver: "null"
      matchers: ['alertname = "InfoInhibitor"']
    - receiver: "null"
      matchers: ['severity = "info"']
inhibit_rules:
  - source_matchers: ['severity = "critical"']
    target_matchers: ['severity =~ "warning|info"']
    equal: [namespace, alertname]
  - source_matchers: ['severity = "warning"']
    target_matchers: ['severity = "info"']
    equal: [namespace, alertname]
  - source_matchers: ['alertname = "InfoInhibitor"']
    target_matchers: ['severity = "info"']
    equal: [namespace]
  - target_matchers: ['alertname = "InfoInhibitor"']
receivers:
  - name: "null"
  - name: telegram
    telegram_configs:
      - bot_token: '${TELEGRAM_BOT_TOKEN}'
        chat_id: ${chat_id}
        parse_mode: HTML
        send_resolved: true
templates:
  - /etc/alertmanager/config/*.tmpl
EOF
)
printf '%s' "$config" | vault kv patch kv/platform/alertmanager config=- >/dev/null
echo "kv/platform/alertmanager güncellendi"

# 2) ExternalSecret'ı hemen yenile, operatörün yeni yapılandırmayı yüklemesini bekle
ssh "root@$APP_HOST" "kubectl annotate externalsecret -n monitoring alertmanager-config force-sync=$(date +%s) --overwrite" >/dev/null
for _ in $(seq 1 30); do
  n=$(ssh "root@$APP_HOST" 'ip=$(kubectl get pod -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0 -o jsonpath="{.status.podIP}");
      curl -s -m 5 "http://$ip:9093/api/v2/status" | grep -o "telegram_configs" | wc -l')
  [ "${n:-0}" -gt 0 ] && break
  sleep 10
done
[ "${n:-0}" -gt 0 ] || die "Alertmanager 5 dk içinde yeni yapılandırmayı yüklemedi (operator / config-reloader loglarına bak)"
echo "Alertmanager telegram alıcısını yükledi"

# 3) Sunucu betikleri: talay-backup (talay-app) ve talay-watch (eski sunucu)
envfile=$(printf 'TELEGRAM_BOT_TOKEN=%s\nTELEGRAM_CHAT_ID=%s\n' "$TELEGRAM_BOT_TOKEN" "$chat_id")
printf '%s\n' "$envfile" | ssh "root@$APP_HOST" 'umask 077; cat > /etc/talay-backup/telegram.env'
printf '%s\n' "$envfile" | ssh "root@$WATCH_HOST" 'umask 077; cat > /etc/talay-watch/telegram.env'
echo "telegram.env: $APP_HOST:/etc/talay-backup, $WATCH_HOST:/etc/talay-watch"

# 4) Uçtan uca deneme: Alertmanager'a 5 dakikalık deneme alarmı
ends=$(date -u -d '+5 min' +%Y-%m-%dT%H:%M:%SZ)
ssh "root@$APP_HOST" "ip=\$(kubectl get pod -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0 -o jsonpath='{.status.podIP}');
  curl -fsS -m 10 -H 'Content-Type: application/json' -X POST http://\$ip:9093/api/v2/alerts -d '[{\"labels\":{\"alertname\":\"TalayTelegramTest\",\"severity\":\"warning\",\"namespace\":\"monitoring\"},\"annotations\":{\"summary\":\"Alertmanager -> Telegram deneme alarmı\"},\"endsAt\":\"$ends\"}]'" >/dev/null
echo "deneme alarmı gönderildi: ~30 sn içinde @$bot sohbetine düşmeli (5 dk sonra 'resolved')"
