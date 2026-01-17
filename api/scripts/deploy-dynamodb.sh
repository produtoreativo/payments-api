#!/usr/bin/env bash

set -euo pipefail

# ============================
# Configurações
# ============================
STACK_NAME="payments-gateway-dynamodb"
TEMPLATE_FILE="infra/dynamodb.yaml"
AWS_PROFILE="dev-schola"
AWS_REGION="us-east-1"

# ============================
# Validações básicas
# ============================
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ Template CloudFormation não encontrado: $TEMPLATE_FILE"
  exit 1
fi

echo "🚀 Iniciando deploy do DynamoDB"
echo "📦 Stack: $STACK_NAME"
echo "👤 Profile: $AWS_PROFILE"
echo "🌍 Região: $AWS_REGION"
echo "📄 Template: $TEMPLATE_FILE"
echo "-----------------------------------"

# ============================
# Deploy
# ============================
aws cloudformation deploy \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset

echo "-----------------------------------"
echo "✅ Deploy finalizado com sucesso"