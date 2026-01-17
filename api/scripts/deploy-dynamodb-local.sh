#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""
export AWS_ENDPOINT_URL=http://localhost.localstack.cloud:4566

STACK_NAME="payments-gateway-dynamodb"
TEMPLATE="infra/dynamodb.yaml"

echo "🚀 Deploy DynamoDB (LocalStack)"
echo "📦 Stack: $STACK_NAME"
echo "📄 Template: $TEMPLATE"
echo "-----------------------------------"

if aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --endpoint-url "$AWS_ENDPOINT_URL" >/dev/null 2>&1; then

  echo "🔁 Stack existe, atualizando..."
  aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --endpoint-url "$AWS_ENDPOINT_URL"

else
  echo "🆕 Stack não existe, criando..."
  aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --endpoint-url "$AWS_ENDPOINT_URL"
fi

echo "✅ Deploy finalizado"