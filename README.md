# Material para estudo do curso de Prodops Reliability Engineer

## Disclaimer

O material executado aqui é baseado no MacOS, adapte para seu SO.  

### Pré-requisitos

Ter instalado o docker (ou o runtime de containers de preferência), AWS SAM CLI, AWS CLI e Localstack

```sh
sam --version
aws --version
docker ps | grep localstack
# SAM CLI, version 1.136.0
# aws-cli/2.25.6 Python/3.12.9 Darwin/24.6.0 source/arm64
# 55e812de7349   localstack/localstack        "docker-entrypoint.sh"   55 minutes ago   Up 55 minutes (healthy)   127.0.0.1:4510-4559->4510-4559/tcp, 127.0.0.1:4566->4566/tcp, 5678/tcp   localstack
```

Lembre de configurar o seu aws local:
```sh
aws configure

# AWS Access Key ID: test
# AWS Secret Access Key: test
# Default region name: us-east-1
# Default output format: json
```

## Executando ambiente serverless local

Utilizo o [localstack](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/lambda-localstack.html) como Docker:

```sh
docker run -d \
  --name localstack \
  --rm -it \
  -p 127.0.0.1:4566:4566 \
  -p 127.0.0.1:4510-4559:4510-4559 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack
```

Deploy um bucket local (que será usado para deployar a lambda) para verificar se está tudo funcionando

```sh
aws s3 mb s3://payments-gateway-prod --endpoint-url=http://localhost.localstack.cloud:4566
```

Listar o Bucket
```sh
aws s3 ls --endpoint-url=http://localhost.localstack.cloud:4566
```

## Cria o Dynamodb

```sh
chmod +x ./scripts/deploy-dynamodb-local.sh
./scripts/deploy-dynamodb-local.sh
```

## Executando a Lambda

Execute o build
```sh
chmod +x ./scripts/build.sh
./scripts/build.sh
```

Deploy local
```sh
chmod +x ./scripts/deploy.sh
./scripts/deploy.sh
```

Crie uma rota para a lambda dado que o localstack exige licença para usar o API Gateway v2
```sh
# verifique se está tudo certo na lambda
aws --endpoint-url=http://localhost.localstack.cloud:4566 \
  lambda list-functions

# criar a rota
aws --endpoint-url=http://localhost.localstack.cloud:4566 \
  lambda create-function-url-config \
  --function-name payments-api \
  --auth-type NONE

# quando precisar pegar a url novamente
aws --endpoint-url=http://localhost.localstack.cloud:4566 \
  lambda get-function-url-config \
  --function-name payments-api 
```

Apagar a Stack

```sh
# Listar as stacks
aws --endpoint-url=http://localhost.localstack.cloud:4566 cloudformation list-stacks

# Apagar
aws --endpoint-url=http://localhost.localstack.cloud:4566 cloudformation delete-stack --stack-name payments-gateway
```