#!/bin/bash
set -e
export AWS_PAGER=""

echo "Deploying to localstack..."
export AWS_ENDPOINT_URL=http://localhost.localstack.cloud:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

sam deploy \
  --template-file infra/consumer-lambda.yaml \
  --stack-name payments-gateway \
  --s3-bucket payments-gateway-prod \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_IAM

echo "Deployed to localstack"