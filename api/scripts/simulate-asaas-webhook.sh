#!/usr/bin/env bash
set -euo pipefail

# WEBHOOK_URL="http://localhost:3000/webhook/payments"

WEBHOOK_URL="http://8kjtuyp67bdzwkophftv5h1p5wxwvbzl.lambda-url.us-east-1.localhost.localstack.cloud:4566/webhook/payments"

echo "📡 Simulando webhook da Asaas"
echo "➡️  POST $WEBHOOK_URL"
echo "-----------------------------------"

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Asaas-Webhook" \
  -d '{
    "event": "PAYMENT_CONFIRMED",
    "payment": {
      "id": "pay_asaas_1234",
      "status": "CONFIRMED",
      "value": 199.90,
      "billingType": "BOLETO",
      "customer": "cus_asaas_456",
      "description": "Mensalidade Turma 123",
      "dueDate": "2026-01-10",
      "confirmedDate": "2026-01-01",
      "externalReference": "TENANT#schola#PAYMENT#pay_asaas_123"
    }
  }'

echo
echo "✅ Webhook enviado com sucesso"