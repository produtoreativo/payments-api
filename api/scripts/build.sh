#!/usr/bin/env bash
set -euo pipefail

echo "🏗️ Build NestJS"
yarn build

echo "📦 SAM build"
sam build --use-container --template-file infra/consumer-lambda.yaml 