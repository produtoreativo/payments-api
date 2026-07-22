# Experiment Upstream Trail — 011 DynamoDB Optimization

Referência:

`prodops/journeys/discovery/experiments/011-dynamodb-optimization/experiment.md`

---

# History

---

## 2026-07-21 21:30

### Activity

Experimento iniciado — implementação e deploy das mudanças DynamoDB em staging.

### Summary

Implementadas todas as mudanças autorizadas em `api/infra/dynamodb.yaml` e `api/infra/lambda.yaml`:
PAY_PER_REQUEST em todas as tabelas, PITR em 5 tabelas críticas, remoção do GSI2 (PaymentStatusIndex)
da PaymentsTable, remoção do GSI1 da TransactionsTable, remoção completa da ProvidersTable
(recurso, output, env var, IAM policies).

Deploy em staging executado via `aws cloudformation deploy` no stack `payments-api-dynamo-staging`.
Lambda stack re-deployed via `sam deploy` para remover PROVIDERS_TABLE e IAM references.

### Artifacts Updated

- `api/infra/dynamodb.yaml` — PAY_PER_REQUEST, PITR, remoção de GSIs e ProvidersTable
- `api/infra/lambda.yaml` — remoção de PROVIDERS_TABLE e referências nas IAM policies
- `prodops/journeys/discovery/experiments/011-dynamodb-optimization/experiment.md` — criado
- `prodops/journeys/discovery/experiments/011-dynamodb-optimization/upstream-trail.md` — criado (este arquivo)
- `prodops/journeys/discovery/experiments.md` — entrada 011 adicionada

### Evidence

**DynamoDB stack deploy — `payments-api-dynamo-staging`:**

```
aws cloudformation deploy
  --stack-name payments-api-dynamo-staging
  --parameter-overrides EnvironmentName=staging

Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - payments-api-dynamo-staging
```

**Stack resources — todos `UPDATE_COMPLETE`:**

```
CustomersTable    UPDATE_COMPLETE  AWS::DynamoDB::Table
PaymentsTable     UPDATE_COMPLETE  AWS::DynamoDB::Table
TenantsTable      UPDATE_COMPLETE  AWS::DynamoDB::Table
TransactionsTable UPDATE_COMPLETE  AWS::DynamoDB::Table
WebhooksTable     UPDATE_COMPLETE  AWS::DynamoDB::Table
```

**Billing mode confirmado (todas as tabelas):**

```
staging-PaymentsTable:     PAY_PER_REQUEST
staging-TransactionsTable: PAY_PER_REQUEST
staging-TenantsTable:      PAY_PER_REQUEST
staging-CustomersTable:    PAY_PER_REQUEST
staging-WebhooksTable:     PAY_PER_REQUEST
```

**PITR confirmado (todas as tabelas):**

```
staging-PaymentsTable:     PITR=ENABLED
staging-TransactionsTable: PITR=ENABLED
staging-TenantsTable:      PITR=ENABLED
staging-CustomersTable:    PITR=ENABLED
staging-WebhooksTable:     PITR=ENABLED
```

**GSIs após deploy:**

```
staging-PaymentsTable:  [ProviderPaymentIndex]   (GSI2/PaymentStatusIndex removido ✅)
staging-TransactionsTable: []                    (GSI1 removido ✅)
staging-WebhooksTable:  [TenantWebhooksIndex]    (GSI1 mantido — em uso)
```

**ProvidersTable:** não está no stack (removida ✅)

**Lambda stack re-deploy** executado via `sam deploy` com parâmetros explícitos para remover
`PROVIDERS_TABLE` env var e referências IAM das funções em runtime.

### Decision

Pronto para Downstream — aplicar as mesmas mudanças em produção via `deploy-production.yml` (EXP-012).

### Notes

- PITR confirmado via `aws dynamodb describe-continuous-backups` (não via `describe-table` —
  `RestoreSummary` só é populado em tabelas restauradas de backup, não em tabelas com PITR habilitado)
- ProvidersTable verificada como inexistente no stack antes da remoção — nenhum dado perdido
- Lambda stack re-deploy necessário para remover `PROVIDERS_TABLE` do ambiente de runtime das funções
