#!/usr/bin/env bash
# test-multi-payment.sh — EXP-007 Split Payment
#
# Valida que múltiplas invoices podem ser criadas para o mesmo orderId
# sem colisão de invoiceId, externalReference ou providerPaymentId.
#
# Hipótese testada:
#   "É possível criar N invoices independentes para o mesmo orderId,
#    cada uma com externalReference e providerPaymentId únicos."
#
# Uso:
#   ./evidence/test-multi-payment.sh [experiment|local]
#
#   experiment  — Sandbox AWS real (lê EXPERIMENT_API_URL de api/.env)
#   local       — http://localhost:3011 (requer app rodando localmente)
#
# Sem argumento: usa 'experiment' se EXPERIMENT_API_URL estiver preenchido,
#                senão cai para 'local'.
#
# Variáveis opcionais (sobrescrevem api/.env):
#   EXPERIMENT_API_URL       URL da Lambda no sandbox AWS
#   EXPERIMENT_API_TOKEN     Token de API já provisionado
#   EXPERIMENT_ADMIN_SECRET  Cria token automaticamente via /admin/tokens
#   ORDER_ID                 ID do pedido (default: gerado com timestamp)

set -euo pipefail

# ── Localiza raiz do repositório ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"
ENV_FILE="$REPO_ROOT/api/.env"

# ── Cores ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

pass()   { echo -e "  ${GREEN}✓ PASS${RESET} — $*"; }
fail()   { echo -e "  ${RED}✗ FAIL${RESET} — $*"; FAILURES=$((FAILURES + 1)); }
info()   { echo -e "  ${CYAN}→${RESET} $*"; }
header() { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}"; }
warn()   { echo -e "  ${YELLOW}!${RESET} $*"; }

FAILURES=0

# ── Lê api/.env sem expansão de variáveis ────────────────────────────────────
read_env_file() {
  local key="$1"
  [[ -f "$ENV_FILE" ]] || return 0
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '"'\''[:space:]' || true
}

# ── Escolha de ambiente ───────────────────────────────────────────────────────
ENV_URL_FROM_FILE=$(read_env_file "EXPERIMENT_API_URL")

if [[ -n "${1:-}" ]]; then
  TARGET="$1"
elif [[ -n "$ENV_URL_FROM_FILE" ]]; then
  TARGET="experiment"
else
  TARGET="local"
fi

case "$TARGET" in
  experiment)
    BASE_URL="${EXPERIMENT_API_URL:-$ENV_URL_FROM_FILE}"
    if [[ -z "$BASE_URL" ]]; then
      echo -e "${RED}ERRO:${RESET} EXPERIMENT_API_URL não está definido em api/.env."
      echo ""
      echo "Execute primeiro:"
      echo "  ./scripts/sync-experiment-env.sh"
      exit 1
    fi
    BASE_URL="${BASE_URL%/}"
    TENANT_ID="exp-007-multi-payment"
    CUSTOMER_ID="exp007-customer-001"
    ;;
  local)
    BASE_URL="http://localhost:3011"
    TENANT_ID="exp-007-local"
    CUSTOMER_ID="exp007-customer-local"
    ;;
  *)
    echo -e "${RED}Ambiente inválido: '$TARGET'. Use 'experiment' ou 'local'.${RESET}" >&2
    exit 1
    ;;
esac

# ── Resolve token de API ──────────────────────────────────────────────────────
API_TOKEN="${EXPERIMENT_API_TOKEN:-$(read_env_file "EXPERIMENT_API_TOKEN")}"

if [[ -z "$API_TOKEN" && "$TARGET" == "experiment" ]]; then
  ADMIN_SECRET="${EXPERIMENT_ADMIN_SECRET:-$(read_env_file "EXPERIMENT_ADMIN_SECRET")}"
  if [[ -n "$ADMIN_SECRET" ]]; then
    info "EXPERIMENT_API_TOKEN não encontrado — criando via /admin/tokens..."
    TMPF=$(mktemp)
    HTTP_ADMIN=$(curl -s -o "$TMPF" -w "%{http_code}" \
      -X POST "${BASE_URL}/admin/tokens" \
      -H "X-Admin-Secret: ${ADMIN_SECRET}" \
      -H "Content-Type: application/json" \
      -d "{\"tenantId\":\"${TENANT_ID}\",\"label\":\"exp-007-test\"}" \
      --max-time 30 || echo "000")
    ADMIN_BODY=$(cat "$TMPF"); rm -f "$TMPF"
    if [[ "$HTTP_ADMIN" == "201" ]]; then
      API_TOKEN=$(echo "$ADMIN_BODY" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || true)
      pass "Token criado via /admin/tokens"
      info "Para reutilizar: adicione EXPERIMENT_API_TOKEN=${API_TOKEN} em api/.env"
    else
      echo -e "${RED}ERRO:${RESET} Não foi possível criar token (HTTP ${HTTP_ADMIN})."
      echo "$ADMIN_BODY" | python3 -m json.tool 2>/dev/null || echo "$ADMIN_BODY"
      exit 1
    fi
  else
    echo -e "${RED}ERRO:${RESET} Nenhum token disponível para ambiente 'experiment'."
    echo ""
    echo "Defina um dos seguintes em api/.env ou como variável de ambiente:"
    echo "  EXPERIMENT_API_TOKEN=<token já criado>"
    echo "  EXPERIMENT_ADMIN_SECRET=<secret para criar token>"
    exit 1
  fi
fi

if [[ -z "$API_TOKEN" && "$TARGET" == "local" ]]; then
  API_TOKEN="local-dev-token-insecure-do-not-use-in-prod"
fi

ORDER_ID="${ORDER_ID:-EXP007-$(date +%s)}"
DUE_DATE=$(date -v+30d '+%Y-%m-%d' 2>/dev/null || date -d '+30 days' '+%Y-%m-%d')

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  EXP-007 Split Payment — Teste de multi-pagamento"
echo -e "  Ambiente  : ${YELLOW}${TARGET}${RESET}"
echo -e "  URL       : ${BASE_URL}"
echo -e "  orderId   : ${ORDER_ID}"
echo -e "  Hipótese  : múltiplas invoices por pedido sem colisão"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ── Helper: faz POST /invoices e retorna a resposta ───────────────────────────
create_invoice() {
  local idem_key="$1" billing_type="$2" amount="$3" label="$4"
  local tmpf; tmpf=$(mktemp)
  local http_status
  http_status=$(curl -s -o "$tmpf" -w "%{http_code}" \
    -X POST "${BASE_URL}/invoices" \
    -H "X-Api-Token: ${API_TOKEN}" \
    -H "Idempotency-Key: ${idem_key}" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"${TENANT_ID}\",
      \"orderId\": \"${ORDER_ID}\",
      \"customer\": {
        \"id\": \"${CUSTOMER_ID}\",
        \"name\": \"João Experimento\",
        \"document\": \"12345678909\",
        \"email\": \"exp007@teste.com\",
        \"mobilePhone\": \"11999990007\"
      },
      \"amount\": ${amount},
      \"currency\": \"BRL\",
      \"dueDate\": \"${DUE_DATE}\",
      \"billingType\": \"${billing_type}\",
      \"provider\": \"ASAAS\",
      \"description\": \"EXP-007 ${label} — ${ORDER_ID}\"
    }" \
    --max-time 30)
  local body; body=$(cat "$tmpf"); rm -f "$tmpf"
  echo "${http_status}|${body}"
}

# ── Helper: extrai campo JSON ─────────────────────────────────────────────────
json_field() {
  local json="$1" field="$2"
  echo "$json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('$field',''))" 2>/dev/null || true
}

# ── Teste 1: Auth guard ───────────────────────────────────────────────────────
header "1. Auth guard — sem token deve retornar 401"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${BASE_URL}/invoices" \
  -H "Content-Type: application/json" \
  -d '{}' --max-time 15)

[[ "$STATUS" == "401" ]] \
  && pass "Sem token → 401" \
  || fail "Esperado 401, recebido ${STATUS}"

# ── Teste 2: Primeira invoice (PIX) ──────────────────────────────────────────
header "2. Invoice 1 — PIX R\$100,00"
info "POST /invoices  billingType=PIX  amount=100.00"

RESULT1=$(create_invoice "${ORDER_ID}:pix" "PIX" "100.00" "Método 1 PIX")
HTTP1="${RESULT1%%|*}"; BODY1="${RESULT1#*|}"

echo -e "\n  ${BOLD}HTTP:${RESET} ${HTTP1}"
echo "$BODY1" | python3 -m json.tool 2>/dev/null | sed 's/^/  /' || echo "  $BODY1"

if [[ "$HTTP1" == "201" ]]; then
  pass "Invoice 1 criada (HTTP 201)"
  INVOICE_ID_1=$(json_field "$BODY1" "invoiceId")
  EXT_REF_1=$(json_field "$BODY1" "externalReference")
  PROVIDER_ID_1=$(json_field "$BODY1" "providerPaymentId")
  ORDER_RETURNED_1=$(json_field "$BODY1" "orderId")
  STATUS_1=$(json_field "$BODY1" "status")

  [[ "$INVOICE_ID_1" =~ ^inv_ ]]  && pass "invoiceId começa com 'inv_': ${INVOICE_ID_1}" \
                                   || fail "invoiceId inválido: ${INVOICE_ID_1}"
  [[ "$EXT_REF_1" =~ ^inv_ ]]     && pass "externalReference começa com 'inv_': ${EXT_REF_1}" \
                                   || fail "externalReference inválido: ${EXT_REF_1}"
  [[ -n "$PROVIDER_ID_1" ]]       && pass "providerPaymentId presente: ${PROVIDER_ID_1}" \
                                   || fail "providerPaymentId ausente"
  [[ "$ORDER_RETURNED_1" == "$ORDER_ID" ]] \
                                   && pass "orderId correto: ${ORDER_ID}" \
                                   || fail "orderId incorreto: esperado ${ORDER_ID}, recebido ${ORDER_RETURNED_1}"
  [[ "$STATUS_1" == "OPEN" ]]     && pass "status = OPEN" \
                                   || fail "status esperado OPEN, recebido ${STATUS_1}"
else
  fail "Invoice 1 falhou (HTTP ${HTTP1})"
  [[ "$HTTP1" == "401" ]] && warn "Token inválido — verifique EXPERIMENT_API_TOKEN ou EXPERIMENT_ADMIN_SECRET"
  exit $((FAILURES + 1))
fi

# ── Teste 3: Segunda invoice (Cartão) — mesmo orderId ────────────────────────
header "3. Invoice 2 — Cartão de Crédito R\$150,00 — mesmo orderId"
info "POST /invoices  billingType=CREDIT_CARD  amount=150.00  orderId=${ORDER_ID}"

RESULT2=$(create_invoice "${ORDER_ID}:card" "CREDIT_CARD" "150.00" "Método 2 Cartão")
HTTP2="${RESULT2%%|*}"; BODY2="${RESULT2#*|}"

echo -e "\n  ${BOLD}HTTP:${RESET} ${HTTP2}"
echo "$BODY2" | python3 -m json.tool 2>/dev/null | sed 's/^/  /' || echo "  $BODY2"

if [[ "$HTTP2" == "201" ]]; then
  pass "Invoice 2 criada (HTTP 201)"
  INVOICE_ID_2=$(json_field "$BODY2" "invoiceId")
  EXT_REF_2=$(json_field "$BODY2" "externalReference")
  PROVIDER_ID_2=$(json_field "$BODY2" "providerPaymentId")
  ORDER_RETURNED_2=$(json_field "$BODY2" "orderId")
  STATUS_2=$(json_field "$BODY2" "status")

  [[ "$INVOICE_ID_2" =~ ^inv_ ]]  && pass "invoiceId começa com 'inv_': ${INVOICE_ID_2}" \
                                   || fail "invoiceId inválido: ${INVOICE_ID_2}"
  [[ "$EXT_REF_2" =~ ^inv_ ]]     && pass "externalReference começa com 'inv_': ${EXT_REF_2}" \
                                   || fail "externalReference inválido: ${EXT_REF_2}"
  [[ -n "$PROVIDER_ID_2" ]]       && pass "providerPaymentId presente: ${PROVIDER_ID_2}" \
                                   || fail "providerPaymentId ausente"
  [[ "$ORDER_RETURNED_2" == "$ORDER_ID" ]] \
                                   && pass "orderId correto: ${ORDER_ID}" \
                                   || fail "orderId incorreto: esperado ${ORDER_ID}, recebido ${ORDER_RETURNED_2}"
  [[ "$STATUS_2" == "OPEN" ]]     && pass "status = OPEN" \
                                   || fail "status esperado OPEN, recebido ${STATUS_2}"
else
  fail "Invoice 2 falhou (HTTP ${HTTP2})"
  exit $((FAILURES + 1))
fi

# ── Teste 4: Isolamento — IDs não podem colidir ───────────────────────────────
header "4. Isolamento — as duas invoices devem ter IDs únicos"

[[ "$INVOICE_ID_1" != "$INVOICE_ID_2" ]] \
  && pass "invoiceId únicos: ${INVOICE_ID_1} ≠ ${INVOICE_ID_2}" \
  || fail "COLISÃO de invoiceId: ambas retornaram ${INVOICE_ID_1}"

[[ "$EXT_REF_1" != "$EXT_REF_2" ]] \
  && pass "externalReference únicos: ${EXT_REF_1} ≠ ${EXT_REF_2}" \
  || fail "COLISÃO de externalReference: ambas retornaram ${EXT_REF_1} — bug de correlação no Asaas"

[[ "$PROVIDER_ID_1" != "$PROVIDER_ID_2" ]] \
  && pass "providerPaymentId únicos: ${PROVIDER_ID_1} ≠ ${PROVIDER_ID_2}" \
  || fail "COLISÃO de providerPaymentId: ambas têm o mesmo ID no Asaas"

# ── Teste 5: GET /invoices/:invoiceId ─────────────────────────────────────────
header "5. GET /invoices/:invoiceId — consulta individual"

for IDINV in "$INVOICE_ID_1" "$INVOICE_ID_2"; do
  TMPF=$(mktemp)
  HTTP_GET=$(curl -s -o "$TMPF" -w "%{http_code}" \
    "${BASE_URL}/invoices/${IDINV}" \
    -H "X-Api-Token: ${API_TOKEN}" \
    -H "X-Tenant-Id: ${TENANT_ID}" \
    --max-time 15)
  GET_BODY=$(cat "$TMPF"); rm -f "$TMPF"

  if [[ "$HTTP_GET" == "200" ]]; then
    RETURNED_ID=$(json_field "$GET_BODY" "invoiceId")
    [[ "$RETURNED_ID" == "$IDINV" ]] \
      && pass "GET /invoices/${IDINV} → invoiceId correto" \
      || fail "GET /invoices/${IDINV} retornou invoiceId errado: ${RETURNED_ID}"
  else
    fail "GET /invoices/${IDINV} retornou HTTP ${HTTP_GET} (esperado 200)"
  fi
done

# ── Teste 6: Idempotência ─────────────────────────────────────────────────────
header "6. Idempotência — mesma Idempotency-Key retorna a mesma invoice"

RESULT_IDEM=$(create_invoice "${ORDER_ID}:pix" "PIX" "100.00" "Método 1 PIX reenvio")
HTTP_IDEM="${RESULT_IDEM%%|*}"; BODY_IDEM="${RESULT_IDEM#*|}"
IDEM_ID=$(json_field "$BODY_IDEM" "invoiceId")

if [[ "$HTTP_IDEM" == "201" && "$IDEM_ID" == "$INVOICE_ID_1" ]]; then
  pass "Retentativa com mesma Idempotency-Key retornou a mesma invoice (${IDEM_ID})"
else
  fail "Idempotência quebrada: esperado ${INVOICE_ID_1}, recebido ${IDEM_ID} (HTTP ${HTTP_IDEM})"
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if [[ $FAILURES -eq 0 ]]; then
  echo -e "  ${GREEN}${BOLD}TODOS OS TESTES PASSARAM${RESET}"
  echo ""
  echo -e "  ${BOLD}Resultado do experimento:${RESET}"
  echo -e "  orderId          : ${ORDER_ID}"
  echo -e "  Invoice 1 (PIX)  : ${INVOICE_ID_1}"
  echo -e "  Invoice 2 (Card) : ${INVOICE_ID_2}"
  echo ""
  echo -e "  ${GREEN}Hipótese confirmada:${RESET} múltiplas invoices por pedido"
  echo -e "  sem colisão de IDs — modelo de composição é viável."
else
  echo -e "  ${RED}${BOLD}${FAILURES} TESTE(S) FALHARAM${RESET}"
fi

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

exit $FAILURES
