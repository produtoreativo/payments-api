#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""
export AWS_ENDPOINT_URL=http://localhost.localstack.cloud:4566

TMP_BUILD_DIR=.lambda_build_temp

echo "🏗️ Build NestJS"
npm run build

rm -rf $TMP_BUILD_DIR
mkdir -p $TMP_BUILD_DIR

cp -r dist/* $TMP_BUILD_DIR/
cp package.json package-lock.json $TMP_BUILD_DIR/

echo "📦 SAM build"
sam build --debug --use-container --template-file infra/consumer-lambda2.yaml 
# sam build --debug --template-file infra/consumer-lambda2.yaml 