# Infrastructure — Bootstrap Guide

Este diretório contém todos os templates CloudFormation do projeto.
Tudo é IaC — é possível recriar o ambiente do zero a partir deste repositório.

---

## Arquivos

| Arquivo | Stack | Propósito |
|---|---|---|
| `dynamodb.yaml` | `payments-api-dynamo-<env>` | Tabelas DynamoDB por ambiente |
| `lambda.yaml` | `payments-api-<env>` | Lambda, SQS, IAM roles das funções, Log Groups |
| `iam-deploy-role.yaml` | `payments-api-iam-deploy-role` | OIDC provider + role para CI/CD (staging e produção) |
| `iam-experiment-role.yaml` | `payments-api-iam-experiment-role` | Role OIDC para deploys efêmeros de experimentos |

---

## Bootstrap from Zero

Execute na ordem abaixo. Os passos 1 e 2 são **one-time** por conta AWS.
Os passos 3 em diante são executados pelo CI em cada deploy.

### Pré-requisitos

- AWS CLI configurado com credenciais de admin
- `gh` CLI autenticado (`gh auth login`)
- Acesso de admin ao repositório GitHub

---

### Passo 1 — IAM: OIDC provider + deploy role

> **Se a role `payments-api-github-deploy` já existir na conta** (criada manualmente),
> delete-a antes de executar o template — CloudFormation não pode importar roles com
> nome fixo em stacks novos:
> ```bash
> aws iam delete-role-policy --role-name payments-api-github-deploy --policy-name payments-api-github-deploy-policy
> aws iam delete-role --role-name payments-api-github-deploy
> ```

```bash
aws cloudformation deploy \
  --template-file api/infra/iam-deploy-role.yaml \
  --stack-name payments-api-iam-deploy-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=produtoreativo \
    GitHubRepo=payments-api \
    CreateOidcProvider=true
```

> **Nota:** `CreateOidcProvider=true` só na primeira vez. Em atualizações da role,
> omita o parâmetro ou use `CreateOidcProvider=false` (padrão) — o provider é
> account-level e não pode ser recriado se já existir.

---

### Passo 2 — IAM: role para experimentos (opcional)

Necessária apenas se o workflow `experiment-deploy.yml` for usado.

```bash
aws cloudformation deploy \
  --template-file api/infra/iam-experiment-role.yaml \
  --stack-name payments-api-iam-experiment-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=produtoreativo \
    GitHubRepo=payments-api
```

---

### Passo 3 — GitHub: environment + secrets

```bash
# Criar environment production com Required Reviewers
gh api --method PUT /repos/produtoreativo/payments-api/environments/production \
  --input - <<'EOF'
{"reviewers": [{"type": "User", "id": <USER_ID>}], "deployment_branch_policy": null}
EOF

# Secrets de staging (environment: staging)
gh secret set STAGING_ASAAS_TOKEN         --env staging --body "..."
gh secret set STAGING_ASAAS_WEBHOOK_TOKEN --env staging --body "..."
gh secret set STAGING_ADMIN_SECRET        --env staging --body "..."
gh secret set STAGING_DATADOG_API_KEY     --env staging --body "..."

# Secrets de produção (environment: production)
# PRODUCTION_ASAAS_TOKEN deve ser o token da conta LIVE Asaas (não sandbox)
gh secret set PRODUCTION_ASAAS_TOKEN         --env production --body "..."
gh secret set PRODUCTION_ASAAS_WEBHOOK_TOKEN --env production --body "..."
gh secret set PRODUCTION_ADMIN_SECRET        --env production --body "..."
gh secret set PRODUCTION_DATADOG_API_KEY     --env production --body "..."
```

---

### Passo 4 — DynamoDB: criar tabelas por ambiente

```bash
# Staging
aws cloudformation deploy \
  --template-file api/infra/dynamodb.yaml \
  --stack-name payments-api-dynamo-staging \
  --parameter-overrides EnvironmentName=staging \
  --no-fail-on-empty-changeset \
  --tags Environment=staging Project=payments-api ManagedBy=cloudformation

# Produção
aws cloudformation deploy \
  --template-file api/infra/dynamodb.yaml \
  --stack-name payments-api-dynamo-production \
  --parameter-overrides EnvironmentName=production \
  --no-fail-on-empty-changeset \
  --tags Environment=production Project=payments-api ManagedBy=cloudformation
```

---

### Passo 5 — Lambda: deploy via CI

Após os passos anteriores, os workflows de CI fazem o restante automaticamente:

- **Staging:** push em `main` ou `workflow_dispatch` em `.github/workflows/staging-deploy.yml`
- **Produção:** `workflow_dispatch` em `.github/workflows/deploy-production.yml`
  (requer aprovação do Required Reviewer configurado no Passo 3)

---

## Ambientes

| Ambiente | DynamoDB Stack | Lambda Stack | Deploy |
|---|---|---|---|
| staging | `payments-api-dynamo-staging` | `payments-api-staging` | Push em `main` / manual |
| production | `payments-api-dynamo-production` | `payments-api-production` | Manual + Required Reviewer |
| experiment | `payments-api-dynamo-experiment` | `payments-api-experiment` | Manual — stack destruída após experimento |

---

## Atualizar a role de deploy (permissões)

Edite `api/infra/iam-deploy-role.yaml` e re-execute:

```bash
aws cloudformation deploy \
  --template-file api/infra/iam-deploy-role.yaml \
  --stack-name payments-api-iam-deploy-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=produtoreativo \
    GitHubRepo=payments-api
```

> Não passe `CreateOidcProvider=true` em atualizações — o provider já existe.
