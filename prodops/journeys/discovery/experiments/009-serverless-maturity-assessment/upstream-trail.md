# Experiment Upstream Trail — 009 Serverless Maturity Assessment

Referência:

`prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/experiment.md`

---

# History

---

## 2026-07-21 17:00

### Activity

Análise arquitetural DynamoDB — mapeamento de entidades, access patterns e problemas de design.

### Summary

Conduzida análise aprofundada do mapeamento de todas as 6 tabelas DynamoDB e seus repositórios (`InvoiceRepository`, `WebhookRepository`, `TokenRepository`). Foram identificados 8 problemas de design, sendo 3 críticos/altos com impacto direto em produção: loop N+1 no caminho crítico de webhook (`findByProviderPaymentId`), dois índices GSI provisionados que nunca são consultados (infraestrutura morta pagando WCU), e ausência de controle de concorrência em `updateInvoice` (risco de lost update em eventos paralelos). A `ProvidersTable` também foi identificada como tabela morta sem repositório.

O design geral (multi-table por bounded context com single-table dentro de cada contexto) é defensável e correto. Os problemas são de otimização e operacionalidade, não de estrutura fundamental.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/experiment.md` — seção "DynamoDB Architecture Analysis" adicionada com mapeamento completo de entidades, access patterns e tabela comparativa

### Evidence

Arquivos analisados:
- `api/src/modules/invoices/services/invoice-repository.service.ts` — InvoiceRepository completo
- `api/src/modules/webhooks/services/webhook-repository.service.ts` — WebhookRepository completo
- `api/src/modules/auth/token.repository.ts` — TokenRepository completo
- `api/infra/dynamodb.yaml` — definição completa de todas as 6 tabelas e GSIs

Evidências numéricas principais:
- `findByProviderPaymentId`: loop sobre `['ASAAS', 'ITAU']` — 2 queries seriais por evento de webhook no caminho crítico
- `GSI2 PaymentStatusIndex`: 0 chamadas `QueryByIndex` com este índice em todo o codebase
- `GSI1 TransactionsTable`: 0 atribuições de `GSI1PK`/`GSI1SK` em todo o codebase
- `countByTokenId`: chama `findByTokenId()` e retorna `.length` — transferência completa de dados desnecessária
- `ProvidersTable`: referenciada em `samconfig.toml` e `lambda.yaml` como `PROVIDERS_TABLE` — zero usos em `api/src/`

### Decision

Pronto para Assessment (análise completa — 8 problemas documentados com recomendações)

### Notes

Os problemas P2 (GSI2 morto) e P3 (GSI1 TransactionsTable morto) podem ser resolvidos como parte do EXP-011 (migração de billing mode), pois já exigem modificação no `dynamodb.yaml`. Aproveitar o mesmo Downstream slice para consolidar as melhorias de schema.

O problema P1 (loop N+1) deve ser tratado em um slice Downstream separado, pois afeta código de aplicação (`invoice-repository.service.ts`) e requer análise do modelo de dados do webhook antes de implementar.

---

## 2026-07-21 16:00

### Activity

Experimento iniciado — análise estática completa do IaC e handlers Serverless do Payments API.

### Summary

Conduzida análise estática completa dos arquivos de infraestrutura (`api/infra/lambda.yaml`, `api/infra/dynamodb.yaml`, `api/samconfig.toml`) e dos handlers Lambda (`api/src/lambda.ts`, `api/src/webhook-worker.ts`) e da stack de observabilidade (`api/src/observability/`).

O Payments API utiliza **AWS SAM** (não Serverless Framework) com dois stacks separados (DynamoDB stateful + Lambda efêmero). A análise revelou uma fundação estrutural sólida em IAM, mensageria e estrutura IaC, mas lacunas críticas em observabilidade (Datadog desabilitado em todos os ambientes), capacidade de DynamoDB (1 RCU/WCU em modo PROVISIONED sem Auto Scaling), e ausência de pipeline de produção automatizado.

Score de maturidade: **2.5/5** — fundação correta, não operacional em produção com carga real.

Quatro experimentos derivados identificados (EXP-010 a EXP-013) para fechar as lacunas em ordem de prioridade.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/experiment.md` — criado
- `prodops/journeys/discovery/experiments/009-serverless-maturity-assessment/upstream-trail.md` — criado (este arquivo)
- `prodops/journeys/discovery/experiments.md` — entrada 009 adicionada

### Evidence

Análise estática dos seguintes arquivos:

- `api/infra/lambda.yaml` — SAM template completo (2 funções, 2 filas, 3 roles, 2 log groups, condições Datadog)
- `api/infra/dynamodb.yaml` — 6 tabelas DynamoDB em modo PROVISIONED 1 RCU/WCU sem PITR
- `api/samconfig.toml` — 3 ambientes (staging, experiment, production); `DatadogEnabled=false` em todos
- `api/src/lambda.ts` — NestJS + serverless-express com module-level cache
- `api/src/webhook-worker.ts` — NestJS ApplicationContext + SQSBatchResponse + partial batch failure
- `api/src/observability/` — Datadog tracer, 9 custom metrics, business spans, PII redaction, correlação

Principais evidências numéricas:
- DynamoDB: `ProvisionedThroughput: ReadCapacityUnits: 1, WriteCapacityUnits: 1` — 6 tabelas
- Datadog: `DatadogEnabled: false` em staging, experiment e production (samconfig.toml)
- Production deploy: sem workflow `.github/workflows/deploy-production.yml`
- SQS VisibilityTimeout: 60s; Worker Timeout: 30s (relação correta 2×)
- Batch size: 5; maxReceiveCount: 5; DLQ retention: 14 dias

### Decision

Pronto para Assessment

### Notes

Decision Package completo. Recomendação: executar EXP-010 (Datadog) como próximo experimento imediato, seguido de EXP-011 (DynamoDB) e EXP-012 (CI/CD Produção).

Apresentar ao Product Manager e Tech Lead para aprovação do roadmap antes de iniciar os experimentos derivados.

O experimento 009 é de natureza **documental-analítica** — nenhum código de produção foi produzido. Os experimentos derivados produzirão código e evidências executáveis.
