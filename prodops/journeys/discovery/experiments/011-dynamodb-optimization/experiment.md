# Upstream Experiment 011 — DynamoDB Optimization

Localização canônica:

```text
prodops/journeys/discovery/experiments/011-dynamodb-optimization/experiment.md
```

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

Eliminar o risco de throttling do DynamoDB em produção, habilitar recuperação point-in-time
de dados, e remover infraestrutura morta que gera custo sem valor.

Derivado do EXP-009 (Serverless Maturity Assessment) — lacunas críticas identificadas:
DynamoDB PROVISIONED 1 RCU/WCU sem Auto Scaling é risco de throttling imediato sob qualquer
carga real de pagamentos.

---

# Repository Scope Gate

## Escopo de responsabilidade deste repositório

- [x] Persistência
- [x] Comportamento da Payments API
- [x] Testes locais ou evidência executável

## Dependências externas

Nenhuma.

## Decisão de escopo

- [x] Prosseguir como experimento Upstream executável neste repositório

---

# Question to Answer

1. A migração de PROVISIONED para PAY_PER_REQUEST pode ser feita in-place sem downtime?
2. Os GSIs mortos (PaymentStatusIndex, GSI1 TransactionsTable) podem ser removidos sem impacto em código?
3. A ProvidersTable pode ser removida do stack sem impacto em runtime?
4. O PITR é habilitado com uma única alteração de CloudFormation?

---

# Hypothesis

Todas as alterações são mudanças de configuração CloudFormation que o DynamoDB aplica
in-place sem interrupção de serviço:
- BillingMode PROVISIONED → PAY_PER_REQUEST: suportado in-place
- Remoção de GSI: suportada in-place (dados dos atributos permanecem nos items)
- Adição de PITR: additive, sem impacto
- Remoção de ProvidersTable: tabela está vazia (sem repositório), remoção segura

---

# Scope

- `api/infra/dynamodb.yaml`: PAY_PER_REQUEST, PITR, remover GSI2/GSI1 mortos, remover ProvidersTable
- `api/infra/lambda.yaml`: remover `PROVIDERS_TABLE` env var e referências nas IAM policies
- Deploy no stack `payments-api-dynamo-staging`
- Deploy no stack `payments-api-staging` (lambda.yaml atualizado)

---

# Out of Scope

- Alterações no código da aplicação (repositórios, queries)
- Migração de dados
- Implementação do GSI faltante para `findByProviderPaymentId` (EXP separado)

---

# Implementation

## dynamodb.yaml

| Mudança | Tabelas afetadas | Risco |
|---|---|---|
| `BillingMode: PAY_PER_REQUEST` | Todas (6 → 5 após remoção Providers) | Nenhum — in-place |
| Remover `ProvisionedThroughput` | Todas as tabelas e GSIs | Nenhum |
| Remover `PaymentStatusIndex` (GSI2) | PaymentsTable | Nenhum — nunca consultado |
| Remover `GSI2PK`, `GSI2SK` de `AttributeDefinitions` | PaymentsTable | Nenhum — atributos permanecem nos items |
| Remover `GSI1` | TransactionsTable | Nenhum — nunca consultado |
| Remover `GSI1PK`, `GSI1SK` de `AttributeDefinitions` | TransactionsTable | Nenhum |
| `PointInTimeRecoveryEnabled: true` | Payments, Transactions, Customers, Tenants, Webhooks | Nenhum — additive |
| Remover `ProvidersTable` | — | Baixo — tabela sem repositório |

## lambda.yaml

| Mudança | Impacto |
|---|---|
| Remover `PROVIDERS_TABLE` env var | Nenhum — env var nunca lida em código |
| Remover `ProvidersTable` de `ApiFunctionRole` IAM policy | Nenhum — permission nunca usada |
| Remover `ProvidersTable` de `WebhookWorkerRole` IAM policy | Nenhum — permission nunca usada |

---

# Code Produced

Apenas mudanças em arquivos IaC (`dynamodb.yaml`, `lambda.yaml`). Nenhum código de aplicação alterado.

---

# Functional Validation

Deploy em staging bem-sucedido confirma que:
- CloudFormation aceita as mudanças in-place
- Lambda continua operacional após remoção da ProvidersTable e env var
- Tabelas continuam acessíveis com PAY_PER_REQUEST

---

# Technical Findings

## PAY_PER_REQUEST vs PROVISIONED

- PAY_PER_REQUEST não throttleia — DynamoDB escala automaticamente
- Custo: por request (WCU/RCU consumida) em vez de capacidade alocada
- Para volume imprevisível e baixo (<10K requests/dia): PAY_PER_REQUEST é mais barato E mais seguro
- Migração in-place: CloudFormation atualiza a tabela sem indisponibilidade

## GSI removal

- DynamoDB suporta remoção de GSI in-place via UpdateTable
- Atributos usados como chaves do GSI (`GSI2PK`, `GSI2SK`, `GSI1PK`, `GSI1SK`) continuam
  presentes nos items existentes — remoção do índice não deleta os atributos
- Aplicação continua gravando esses atributos sem erro (atributos extras são ignorados)

## PITR

- Habilitado via `PointInTimeRecoverySpecification: PointInTimeRecoveryEnabled: true`
- Permite restauração para qualquer ponto nos últimos 35 dias
- Custo: proporcional ao tamanho da tabela (baixo para volumes atuais)

## ProvidersTable

- Tabela existe no stack mas não tem repositório em `api/src/`
- A env var `PROVIDERS_TABLE` é injetada no Lambda mas nunca lida
- Remoção do CloudFormation stack deleta a tabela — confirmado que está vazia

---

# Architecture Impact

## Decisões confirmadas

- PAY_PER_REQUEST é o padrão correto para workloads com tráfego variável
- Remover índices não utilizados é manutenção preventiva — reduz WCU desperdiçado
- PITR é obrigatório para dados de pagamento em produção

## Questões em aberto

- Quando implementar o access pattern correto para `findByProviderPaymentId` (N+1 fix)?
  Candidato para EXP separado após análise de acesso por provider ID.

---

# Reliability Impact

| Dimensão | Antes | Depois |
|---|---|---|
| Risco de throttling | Crítico (1 WCU — throttling com ≥2 escritas/s) | Eliminado (PAY_PER_REQUEST) |
| Recuperação de dados | Sem PITR — perda irreversível | PITR 35 dias em todas as tabelas críticas |
| Custo desperdiçado | GSIs mortos pagando WCU em cada escrita | Eliminado |
| Superfície de IAM | Permission para tabela sem uso | Reduzida (ProvidersTable removida) |

---

# Artifacts Updated

- `api/infra/dynamodb.yaml`
- `api/infra/lambda.yaml`
- `prodops/journeys/discovery/experiments/011-dynamodb-optimization/experiment.md`
- `prodops/journeys/discovery/experiments/011-dynamodb-optimization/upstream-trail.md`
- `prodops/journeys/discovery/experiments.md`

---

# Knowledge Gaps Closed

| Pergunta | Status | Evidência |
|---|---|---|
| Migração in-place PAY_PER_REQUEST | ✅ Respondida | CloudFormation UPDATE_COMPLETE sem downtime |
| GSIs mortos removíveis sem impacto | ✅ Respondida | Deploy bem-sucedido, Lambda continua operacional |
| ProvidersTable removível | ✅ Respondida | Deploy bem-sucedido |
| PITR habilitado via CloudFormation | ✅ Respondida | UPDATE_COMPLETE — PITR ativo |

---

# New Backlog Items

| Item | Classificação |
|---|---|
| Implementar fix N+1 em `findByProviderPaymentId` | Repository Tracking List |
| Adicionar alarme CloudWatch na DLQ de webhook | Candidato ao Iteration Backlog |
| Monitorar custo PAY_PER_REQUEST vs. PROVISIONED (Datadog) | Repository Tracking List |

---

# Recommendation

- [x] Mover para Downstream

Deploy em staging confirmou que todas as mudanças são seguras e aplicáveis in-place.
Promover as mesmas mudanças para produção via EXP-012 pipeline.

---

# Decision Package

## Executive Summary

Seis mudanças de configuração IaC aplicadas em staging sem downtime: billing mode PAY_PER_REQUEST,
PITR em 5 tabelas, remoção de 2 GSIs mortos e da ProvidersTable, e limpeza de IAM e env vars.
Risco de throttling eliminado. Recuperação de dados habilitada.

## Decisão Recomendada

Mover para Downstream — aplicar as mesmas mudanças em produção via pipeline EXP-012.

## Riscos Atualizados

| Risco | Situação |
|---|---|
| Throttling DynamoDB em produção | **Eliminado** — PAY_PER_REQUEST |
| Perda de dados sem backup | **Mitigado** — PITR 35 dias |
| Custo de GSIs mortos | **Eliminado** |

## Escopo Downstream Recomendado

Deploy das mesmas mudanças em `payments-api-dynamo-production` via workflow de produção (EXP-012).

---

# Output Artifacts

| Tipo | Artefato | Situação |
|---|---|---|
| IaC | `api/infra/dynamodb.yaml` | Atualizado — staging validado |
| IaC | `api/infra/lambda.yaml` | Atualizado — PROVIDERS_TABLE removida |

**Promovido para Downstream:** `- [x] Sim` — aplicar em produção via EXP-012 pipeline
**Data de promoção:** 2026-07-21
**Slice:** DynamoDB optimization — produção

---

# Exit Criteria

- [x] Hipótese confirmada — mudanças in-place sem downtime
- [x] GSIs mortos removidos
- [x] PITR habilitado
- [x] ProvidersTable removida
- [x] lambda.yaml limpo (PROVIDERS_TABLE e IAM)
- [x] Deploy staging bem-sucedido
- [x] Recomendação produzida

---

# Next Step

Aplicar as mesmas mudanças em produção via pipeline automatizado criado no EXP-012.
