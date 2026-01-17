#!/bin/bash
set -e

export AWS_PAGER=""
export AWS_ENDPOINT_URL=http://localhost.localstack.cloud:4566

TMP_BUILD_DIR=.lambda_build_temp


# rm -rf $TMP_BUILD_DIR
# mkdir -p $TMP_BUILD_DIR

# cp -r dist/* $TMP_BUILD_DIR/
# cp package.json yarn.lock $TMP_BUILD_DIR/

# cd $TMP_BUILD_DIR
# yarn install --production
# cd ..

# sam build --debug --template-file infra/consumer-lambda2.yaml
sam build --debug --template-file infra/consumer-lambda2.yaml 
# rm -rf $TMP_BUILD_DIR