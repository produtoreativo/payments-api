#!/usr/bin/env bash
# check-obc.sh — valida um Local OBC contra o template prodops/templates/obcs/local-obc.md
#
# Uso:
#   check-obc.sh <caminho-do-obc.md> [--skip-code-events] [--repo-root DIR]
#
# Verifica:
#   1. seções obrigatórias do template (PT ou EN)
#   2. estado único e válido na seção Status
#   3. Origem com rastreabilidade (BS-/PI-/Issue)
#   4. placeholders <...> esquecidos (só para Committed ou posterior)
#   5. Observable Events: coluna Situação/Status e nome IDÊNTICO ao emitido no código
#   6. Initial SLIs: coluna Fonte/Source
#   7. BDD Feature existente e links internos que resolvem
#
# Saída: um relatório legível. Exit 0 = sem falhas; exit 1 = há falhas; exit 2 = uso inválido.
# Compatível com bash 3.2 (macOS) e awk BSD.

set -uo pipefail

FILE=""
SKIP_CODE_EVENTS="false"
ROOT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-code-events) SKIP_CODE_EVENTS="true"; shift ;;
    --repo-root)        ROOT="$2"; shift 2 ;;
    -h|--help)          sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)                 echo "Argumento desconhecido: $1" >&2; exit 2 ;;
    *)                  FILE="$1"; shift ;;
  esac
done

[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "Uso: check-obc.sh <obc.md> [--skip-code-events] [--repo-root DIR]" >&2; exit 2; }
[ -n "$ROOT" ] || ROOT="$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null || pwd)"

SLUG="$(basename "$FILE" .md)"
SLUG="${SLUG%.en}"   # o par EN (<slug>.en.md) compartilha BDD e demais artefatos com o PT
FAILS=0
WARNS=0

pass() { echo "  ✅ $*"; }
fail() { echo "  ❌ $*"; FAILS=$((FAILS + 1)); }
warn() { echo "  ⚠️  $*"; WARNS=$((WARNS + 1)); }

# Texto do OBC sem comentários HTML (<!-- ... -->) e sem blocos de código cercados.
strip_noise() {
  awk '
    /^```/ { code = !code; next }
    code { next }
    /<!--/ && /-->/ { next }
    /<!--/ { cmt = 1; next }
    cmt && /-->/ { cmt = 0; next }
    cmt { next }
    { print }
  ' "$1"
}

# Conteúdo de uma seção (título "##" ou "###") cujo título casa com o regex ERE (minúsculas),
# até o próximo título de nível igual ou superior.
section() {
  local re
  re="$(printf '%s' "$1" | tr 'A-Z' 'a-z')"
  awk -v re="$re" '
    { low = tolower($0) }
    /^#+ / {
      match($0, /^#+/)
      lvl = RLENGTH
      if (found && lvl <= startlvl) exit
      if (!found && low ~ ("^#+ ([0-9]+\\. )?(" re ")")) { found = 1; startlvl = lvl; next }
    }
    found { print }
  ' <(strip_noise "$FILE")
}

has_section() {
  strip_noise "$FILE" | awk -v re="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" '
    { low = tolower($0) }
    /^##+ / && low ~ ("^##+ ([0-9]+\\. )?(" re ")") { ok = 1 }
    END { exit ok ? 0 : 1 }
  '
}

echo "OBC: $FILE"

# ── 1. Seções obrigatórias ───────────────────────────────────────────────────
echo "[1] Seções do template"
check_section() {
  if has_section "$2"; then pass "$1"; else fail "seção ausente: $1"; fi
}
check_section "Metadados"          "metadados|metadata"
check_section "Status"             "status"
check_section "Origem"             "origem|origin"
check_section "Business Outcome"   "business outcome"
check_section "Escopo"             "escopo|scope"
check_section "Regras de Negócio"  "regras de neg|business rules"
check_section "Critérios de Aceite" "crit.*rios de aceite|acceptance criteria"
check_section "Contexto Enterprise" "contexto enterprise|enterprise context"
check_section "Observable Events"  "observable events"
check_section "Initial SLIs"       "initial slis"
check_section "Reliability Rules"  "reliability rules"
check_section "Riscos"             "riscos|risks"
check_section "Dependências"       "depend.*ncias|dependencies"
check_section "Decisões"           "decis.*es|decisions"
check_section "Related Artifacts"  "related artifacts"

# ── 2. Estado ────────────────────────────────────────────────────────────────
echo "[2] Status"
STATE=""
STATUS_BODY="$(section 'status')"
STATE_LINE="$(printf '%s\n' "$STATUS_BODY" | grep -iE '^\*\*(estado|state|status):\*\*' | head -1)"
if [ -n "$STATE_LINE" ]; then
  STATE="$(printf '%s' "$STATE_LINE" | sed -E 's/^\*\*[^*]+:\*\*[[:space:]]*//; s/[[:space:]]+$//')"
else
  STATE="$(printf '%s\n' "$STATUS_BODY" | grep -vE '^[[:space:]]*$' | head -1 | sed -E 's/[[:space:]]+$//')"
fi
STATE_NORM="$(printf '%s' "$STATE" | tr 'A-Z' 'a-z')"
case "$STATE_NORM" in
  "draft"|"refining"|"committed"|"in delivery"|"operational"|"archived")
    pass "estado válido: $STATE" ;;
  "")
    fail "estado não declarado" ;;
  *)
    fail "estado inválido ou com texto extra: \"$STATE\" (use exatamente um de: Draft | Refining | Committed | In Delivery | Operational | Archived; mova o resto para 'Rastreado em')" ;;
esac

# Rastreado em / Tracked in
if printf '%s\n' "$STATUS_BODY" | grep -qiE '^\*\*(rastreado em|tracked in):\*\*'; then
  pass "linha 'Rastreado em' presente"
else
  warn "falta a linha 'Rastreado em' / 'Tracked in' na seção Status"
fi

# Estados que exigem OBC completo
STRICT="false"
case "$STATE_NORM" in "committed"|"in delivery"|"operational") STRICT="true" ;; esac

# ── 3. Origem ────────────────────────────────────────────────────────────────
echo "[3] Origem (rastreabilidade)"
if section 'origem|origin' | grep -qE '(BS|PI|POPS-ICE)-[A-Za-z0-9-]+|#[0-9]+'; then
  pass "referência a Business Signal / Intent / Issue encontrada"
else
  if [ "$STRICT" = "true" ]; then fail "Origem sem Business Signal, Business Intent ou Issue"; else warn "Origem ainda sem referência (aceitável em Draft/Refining)"; fi
fi

# ── 4. Placeholders ──────────────────────────────────────────────────────────
echo "[4] Placeholders"
PH_COUNT="$(strip_noise "$FILE" | sed -E 's/`[^`]*`//g' | grep -cE '<[A-Za-zÀ-ÿ][^<>]*>' || true)"
if [ "${PH_COUNT:-0}" -eq 0 ]; then
  pass "nenhum placeholder <...> fora de código"
elif [ "$STRICT" = "true" ]; then
  fail "$PH_COUNT linha(s) com placeholder <...> num OBC $STATE"
else
  warn "$PH_COUNT linha(s) com placeholder <...> (aceitável em Draft/Refining)"
fi

# ── 5. Observable Events ─────────────────────────────────────────────────────
echo "[5] Observable Events"
EVENTS_BODY="$(section 'observable events')"
HEADER_ROW="$(printf '%s\n' "$EVENTS_BODY" | grep -E '^\|' | head -1)"
EVENTS_NA="false"
if [ -z "$HEADER_ROW" ] && printf '%s\n' "$EVENTS_BODY" | grep -qiE 'n.o aplic|not applicable|nenhum (cloud)?event|no new|^none'; then
  EVENTS_NA="true"
fi
HAS_SITUACAO="false"
printf '%s' "$HEADER_ROW" | grep -qiE 'situa|status' && HAS_SITUACAO="true"
if [ "$EVENTS_NA" = "true" ]; then
  pass "Observable Events declarado explicitamente como não aplicável"
elif [ "$HAS_SITUACAO" = "true" ]; then
  pass "coluna Situação/Status presente"
else
  fail "tabela de eventos sem coluna Situação/Status (Emitido | Planejado)"
fi

CODE_FILE=""
if [ "$SKIP_CODE_EVENTS" = "false" ] && [ -d "$ROOT/api/src" ]; then
  CODE_FILE="$(mktemp)"
  # Exclui specs, DTOs (tipos de inscrição, ex.: WebhookEventType) e metrics.ts (métricas Datadog):
  # esses arquivos citam nomes que NÃO são eventos emitidos.
  find "$ROOT/api/src" -name '*.ts' ! -name '*.spec.ts' ! -name '*.dto.ts' ! -path '*/observability/metrics.ts' -print0 | xargs -0 cat > "$CODE_FILE" 2>/dev/null
fi

EV_TOTAL=0
while IFS= read -r ev; do
  [ -z "$ev" ] && continue
  case "$ev" in *"<"*) continue ;; esac
  EV_TOTAL=$((EV_TOTAL + 1))
  ROW="$(printf '%s\n' "$EVENTS_BODY" | grep -F "\`$ev\`" | head -1)"
  PLANNED="false"
  printf '%s' "$ROW" | grep -qiE '\|[[:space:]]*(planejado|planned)[[:space:]]*\|' && PLANNED="true"
  if [ -z "$CODE_FILE" ]; then
    continue
  fi
  if grep -qF "'$ev'" "$CODE_FILE"; then
    pass "evento emitido no código: $ev"
  elif [ "$PLANNED" = "true" ]; then
    warn "evento marcado Planejado (ainda não existe no código): $ev"
  else
    fail "evento NÃO encontrado no código e não marcado Planejado: $ev"
  fi
# Só a PRIMEIRA tabela da seção lista eventos do OBC; tabelas seguintes (ex.: webhook entregue,
# comparações) são auxiliares e não são conferidas contra o código.
done < <(printf '%s\n' "$EVENTS_BODY" | awk '/^\|/ { t = 1; print; next } t { exit }' | grep -E '^\|[[:space:]]*`' | sed -E 's/^\|[[:space:]]*`([^`]+)`.*/\1/')

if [ "$EV_TOTAL" -eq 0 ] && [ "$EVENTS_NA" != "true" ]; then fail "nenhum evento listado em Observable Events"; fi
if [ -z "$CODE_FILE" ]; then warn "verificação contra o código ignorada (--skip-code-events ou api/src ausente)"; else rm -f "$CODE_FILE"; fi

# ── 6. SLIs ──────────────────────────────────────────────────────────────────
echo "[6] Initial SLIs"
SLI_HEADER="$(section 'initial slis' | grep -E '^\|' | head -1)"
if printf '%s' "$SLI_HEADER" | grep -qiE 'fonte|source'; then pass "coluna Fonte/Source presente"; else fail "tabela de SLIs sem coluna Fonte/Source"; fi

# ── 7. BDD e links ───────────────────────────────────────────────────────────
echo "[7] Artefatos relacionados"
CITED_BDD=""
for b in $(strip_noise "$FILE" | grep -oE 'prodops/artifacts/bdd/[A-Za-z0-9_.-]+\.feature' | sort -u); do
  [ -f "$ROOT/$b" ] && CITED_BDD="$CITED_BDD $b"
done
if [ -f "$ROOT/prodops/artifacts/bdd/$SLUG.feature" ]; then
  pass "BDD existe: prodops/artifacts/bdd/$SLUG.feature"
elif [ -n "$CITED_BDD" ]; then
  pass "BDD(s) citado(s) existem:$CITED_BDD"
elif [ "$STRICT" = "true" ]; then
  fail "BDD ausente: prodops/artifacts/bdd/$SLUG.feature"
else
  warn "BDD ainda não existe: prodops/artifacts/bdd/$SLUG.feature"
fi

BROKEN=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  case "$p" in *"<"*|*"*"*|*"..."*) continue ;; esac
  if [ ! -e "$ROOT/$p" ]; then
    fail "caminho citado não existe: $p"
    BROKEN=$((BROKEN + 1))
  fi
done < <(strip_noise "$FILE" | grep -oE '`prodops/[A-Za-z0-9_./-]+\.(md|feature|json|ya?ml)`' | tr -d '`' | sort -u)
[ "$BROKEN" -eq 0 ] && pass "caminhos prodops/… citados existem"

# ── Resumo ───────────────────────────────────────────────────────────────────
echo "Resumo: $FAILS falha(s), $WARNS aviso(s) — estado: ${STATE:-n/d}"
[ "$FAILS" -eq 0 ]
