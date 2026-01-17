#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""

STACK_NAME="payments-transactions-sqs"
TEMPLATE_FILE="infra/sqs-transactions.yaml"
REGION="us-east-1"

# LocalStack (comente se for AWS real)
ENDPOINT_URL="http://localhost.localstack.cloud:4566"

echo "🚀 Deploy da fila SQS (create ou update)"
echo "📦 Stack: $STACK_NAME"
echo "📄 Template: $TEMPLATE_FILE"
echo "🌍 Região: $REGION"
echo "-----------------------------------"

# Verifica se a stack existe
if aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --endpoint-url "$ENDPOINT_URL" \
  >/dev/null 2>&1; then

  echo "🔄 Stack existente, executando update..."

  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --region "$REGION" \
    --endpoint-url "$ENDPOINT_URL"

  echo "⏳ Aguardando update da stack..."
  aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --endpoint-url "$ENDPOINT_URL"

else
  echo "🆕 Stack não encontrada, criando..."

  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --region "$REGION" \
    --endpoint-url "$ENDPOINT_URL"

  echo "⏳ Aguardando criação da stack..."
  aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --endpoint-url "$ENDPOINT_URL"
fi

echo "✅ Deploy concluído com sucesso"