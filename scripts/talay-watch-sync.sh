#!/usr/bin/env bash
# ops/talay-watch/checks listesini eski sunucudaki dış gözcüye kurar, listeden çıkan uçların
# durum dosyalarını siler ve bir tur çalıştırıp durumu yazdırır.
set -euo pipefail
WATCH_HOST=${TALAY_WATCH_HOST:-45.87.80.10}
checks="$(dirname "$0")/../ops/talay-watch/checks"

ssh "root@$WATCH_HOST" 'cp -p /etc/talay-watch/checks /etc/talay-watch/checks.bak-$(date +%F) && cat > /etc/talay-watch/checks' < "$checks"
ssh "root@$WATCH_HOST" 'names=$(awk "!/^#/ && NF {print \$1}" /etc/talay-watch/checks; echo backup)
  for f in /var/lib/talay-watch/*; do n=$(basename "$f"); echo "$names" | grep -qx "$n" || rm -f "$f"; done
  systemctl start talay-watch.service
  for f in /var/lib/talay-watch/*; do printf "%-16s %s (ardışık hata %s)\n" "$(basename "$f")" $(cat "$f"); done'
