#!/usr/bin/env bash
# publish-dashboard.sh — publica (cria ou atualiza) o dashboard gerado do Event Storming no Datadog.
#
# Uso: publish-dashboard.sh <slug>.datadog.json [--apply]
#   sem --apply  DRY-RUN: valida o JSON e a chave de API (somente leitura) e mostra o que faria.
#   --apply      cria (POST) ou atualiza (PUT) o dashboard. Efeito externo: confirme com o dono antes.
#
# O id do dashboard publicado fica em <slug>.datadog.state.json (ao lado do JSON) — assim a
# próxima execução atualiza o mesmo dashboard em vez de criar outro.
# Credenciais: DD_API_KEY, DD_APP_KEY, DD_SITE do ambiente ou de api/.env. Nunca são impressas.
set -euo pipefail

FILE="${1:-}"; APPLY=0
[[ "${2:-}" == "--apply" ]] && APPLY=1
[[ -f "$FILE" ]] || { echo "uso: $0 <slug>.datadog.json [--apply]" >&2; exit 1; }
command -v jq >/dev/null && command -v curl >/dev/null || { echo "jq e curl são necessários" >&2; exit 1; }

REPO="$(cd "$(dirname "$0")/../../../.." && pwd)"
ENV_FILE="$REPO/api/.env"
read_env() { [[ -f "$ENV_FILE" ]] && grep -E "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d "\"'" || true; }
DD_API_KEY="${DD_API_KEY:-$(read_env DD_API_KEY)}"
DD_APP_KEY="${DD_APP_KEY:-$(read_env DD_APP_KEY)}"
DD_SITE="${DD_SITE:-$(read_env DD_SITE)}"; DD_SITE="${DD_SITE:-datadoghq.com}"
[[ -n "$DD_API_KEY" && -n "$DD_APP_KEY" ]] || { echo "DD_API_KEY e DD_APP_KEY são necessárias (ambiente ou api/.env)" >&2; exit 1; }

jq -e '.title and (.widgets | length > 0)' "$FILE" >/dev/null || { echo "JSON de dashboard inválido" >&2; exit 1; }
STATE="${FILE%.json}.state.json"
BASE="https://api.${DD_SITE}"
TITLE="$(jq -r .title "$FILE")"; COUNT="$(jq '.widgets | length' "$FILE")"

# Chaves via arquivo de headers (curl -K) para não aparecerem na lista de processos.
HDR="$(mktemp)"; trap 'rm -f "$HDR" "${BODY:-}"' EXIT; chmod 600 "$HDR"
printf 'header = "DD-API-KEY: %s"\nheader = "DD-APPLICATION-KEY: %s"\nheader = "Content-Type: application/json"\n' \
  "$DD_API_KEY" "$DD_APP_KEY" > "$HDR"

CODE="$(curl -s -o /dev/null -w '%{http_code}' -K "$HDR" "$BASE/api/v1/validate")"
[[ "$CODE" == "200" ]] || { echo "Chave de API inválida ou site errado (HTTP $CODE, site $DD_SITE)" >&2; exit 1; }

if [[ -f "$STATE" ]]; then ID="$(jq -r .id "$STATE")"; ACTION="atualizar $ID (PUT)"; else ID=""; ACTION="criar novo (POST)"; fi
echo "Dashboard: $TITLE ($COUNT blocos) — ação: $ACTION — site: $DD_SITE"
if [[ $APPLY -eq 0 ]]; then echo "DRY-RUN: nada foi enviado. Use --apply para publicar."; exit 0; fi

BODY="$(mktemp)"
if [[ -n "$ID" ]]; then
  CODE="$(curl -s -o "$BODY" -w '%{http_code}' -K "$HDR" -X PUT "$BASE/api/v1/dashboard/$ID" --data-binary @"$FILE")"
else
  CODE="$(curl -s -o "$BODY" -w '%{http_code}' -K "$HDR" -X POST "$BASE/api/v1/dashboard" --data-binary @"$FILE")"
fi
if [[ "$CODE" != "200" ]]; then
  echo "Falha ao publicar (HTTP $CODE): $(jq -r '.errors // . | tostring' "$BODY" | head -c 600)" >&2; exit 1
fi
ID="$(jq -r .id "$BODY")"; URL="https://app.${DD_SITE}$(jq -r .url "$BODY")"
jq -n --arg id "$ID" --arg url "$URL" --arg title "$TITLE" --arg at "$(date -u +%FT%TZ)" \
  '{id:$id,url:$url,title:$title,publishedAt:$at}' > "$STATE"
echo "Publicado: $URL"
