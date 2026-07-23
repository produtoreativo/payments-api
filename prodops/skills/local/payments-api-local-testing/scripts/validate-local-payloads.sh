#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:3011}"
FRONTEND_ORIGIN="${FRONTEND_ORIGIN:-http://localhost:5173}"
ORDER_ID="${ORDER_ID:-MS-SKILL-$(date +%Y%m%d%H%M%S)}"

future_date() {
  if date -v+7d +%Y-%m-%d >/dev/null 2>&1; then
    date -v+7d +%Y-%m-%d
  else
    date -d '+7 days' +%Y-%m-%d
  fi
}

request() {
  local method="$1"
  local path="$2"
  local expected_status="$3"
  local body="${4:-}"
  shift 4 || true

  local response_file
  response_file="$(mktemp)"

  local status
  if [[ -n "$body" ]]; then
    status="$(
      curl -sS -o "$response_file" -w '%{http_code}' \
        -X "$method" "${API_URL}${path}" \
        -H "Origin: ${FRONTEND_ORIGIN}" \
        -H 'Content-Type: application/json' \
        "$@" \
        --data "$body"
    )"
  else
    status="$(
      curl -sS -o "$response_file" -w '%{http_code}' \
        -X "$method" "${API_URL}${path}" \
        -H "Origin: ${FRONTEND_ORIGIN}" \
        "$@"
    )"
  fi

  if [[ "$status" != "$expected_status" ]]; then
    echo "FAIL ${method} ${path}: expected ${expected_status}, got ${status}" >&2
    cat "$response_file" >&2
    rm -f "$response_file"
    exit 1
  fi

  echo "OK ${method} ${path}: ${status}"
  cat "$response_file"
  echo
  rm -f "$response_file"
}

invoice_payload="$(
  cat <<JSON
{
  "tenantId": "magazine-siara",
  "orderId": "${ORDER_ID}",
  "customer": {
    "id": "customer-${ORDER_ID}",
    "name": "Cliente Sandbox Magazine Siara",
    "document": "11144477735",
    "email": "sandbox@example.com",
    "mobilePhone": "11987654321"
  },
  "amount": 109.7,
  "currency": "BRL",
  "dueDate": "$(future_date)",
  "billingType": "PIX",
  "provider": "ASAAS",
  "description": "Pedido ${ORDER_ID}: 1x Camiseta ProdOps, 2x Adesivo Reliability"
}
JSON
)"

payment_payload="$(
  cat <<JSON
{
  "tenantId": "magazine-siara",
  "amount": 109.7,
  "description": "Pedido ${ORDER_ID}: 1x Camiseta ProdOps, 2x Adesivo Reliability",
  "customer": {
    "externalId": "external-${ORDER_ID}",
    "name": "Cliente Sandbox Magazine Siara",
    "email": "sandbox@example.com",
    "cpfCnpj": "11144477735"
  }
}
JSON
)"

request OPTIONS /invoices 204 '' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,idempotency-key,x-correlation-id'

request OPTIONS /payments 204 '' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type'

request POST /invoices 201 "$invoice_payload" \
  -H "Idempotency-Key: ${ORDER_ID}:create" \
  -H "X-Correlation-Id: frontend-${ORDER_ID}"

request POST /payments 201 "$payment_payload"
