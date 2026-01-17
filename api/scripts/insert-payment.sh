#!/usr/bin/env bash

set -euo pipefail

curl -X POST http://localhost:3000/payments \
  -H "Content-Type: application/json" \
  -d '{
    "tenantId": "schola",
    "amount": 199.90,
    "description": "Mensalidade Turma 123",
    "customer": {
      "externalId": "user-123",
      "name": "João da Silva",
      "email": "joao.silva@email.com",
      "cpfCnpj": "12345678909"
    }
  }'