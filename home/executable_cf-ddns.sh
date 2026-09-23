#!/usr/bin/env bash
# Poll public IP every 30s; update ssh.tanayupreti.dev A record on change.
# Needs: CF_API_TOKEN (Zone:DNS:Edit), CF_ZONE_ID
set -uo pipefail

: "${CF_API_TOKEN:?set CF_API_TOKEN}"
: "${CF_ZONE_ID:?set CF_ZONE_ID}"
NAME=ssh.tanayupreti.dev
API=https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records

api() { curl -sf -H "Authorization: Bearer $CF_API_TOKEN" -H 'Content-Type: application/json' "$@"; }

REC=$(api "$API?type=A&name=$NAME" | jq -r '.result[0].id // empty')
[ -n "$REC" ] || { echo "no A record for $NAME"; exit 1; }

last=$(api "$API/$REC" | jq -r '.result.content')
echo "$(date -Is) start, current=$last"

while :; do
  ip=$(curl -4sf --max-time 10 https://cloudflare.com/cdn-cgi/trace | sed -n 's/^ip=//p')
  if [[ $ip =~ ^[0-9.]+$ && $ip != "$last" ]]; then
    if api -X PATCH "$API/$REC" --data "{\"content\":\"$ip\"}" >/dev/null; then
      echo "$(date -Is) $last -> $ip"; last=$ip
    else
      echo "$(date -Is) update failed for $ip" >&2
    fi
  fi
  sleep 30
done
