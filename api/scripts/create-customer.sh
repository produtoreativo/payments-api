#!/usr/bin/env bash
set -euo pipefail

export $(grep -v '^#' .env | xargs)

curl --request POST \
     --url $ASAAS_URL/v3/customers \
     --header "accept: application/json" \
     --header "access_token: $ASAAS_TOKEN" \
     --header "content-type: application/json" \
     --data '
{
  "name": "CHRISTIANO MILFONT",
  "cpfCnpj": "78006325391"
}
'