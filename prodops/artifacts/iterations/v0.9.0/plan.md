# Iteration Plan — v0.9.0

> Status: 🟡 Em andamento — aberta em 2026-08-01

## Objetivo

Entregar a tríade de prontidão para produção: pipeline CI/CD governado, otimização de persistência DynamoDB e instrumentação Datadog. Estas três capabilities habilitam operação confiável do serviço em ambiente de produção.

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | Risco | Status | PR |
|---|---|---|---|---|---|---|---|---|
| DS-48 | #46 | production-cicd-pipeline: pipeline CI/CD para produção com gate de aprovação humana | — | ✓ | ✓ | — | Entrou | — |
| DS-49 | #45 | dynamodb-optimization: otimizar persistência DynamoDB para produção | — | ✓ | ✓ | — | Entrou | — |
| DS-50 | #44 | observability-datadog: instrumentar Payments API com Datadog em produção | — | ✓ | ✓ | — | Entrou | — |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.9.0 |
|---|---|---|
| DS-48 | production-cicd-pipeline | #46 |
| DS-49 | dynamodb-optimization | #45 |
| DS-50 | observability-datadog | #44 |

## Critérios de saída

- [ ] PR merged em `master` para DS-48 (production-cicd-pipeline)
- [ ] PR merged em `master` para DS-49 (dynamodb-optimization)
- [ ] PR merged em `master` para DS-50 (observability-datadog)
- [ ] `prodops.delivery.promote.completed` emitido para cada issue
- [ ] Issues #46, #45 e #44 fechadas no GitHub

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.9.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
