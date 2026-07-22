# Capability — Observability

## Objetivo

Garantir que o comportamento do sistema é visível em produção: logs estruturados, métricas de negócio, rastreabilidade e health checks.

## Responsabilidades

- Emitir eventos de negócio com dimensões obrigatórias (tenantId, correlationId, orderId)
- Garantir que nenhum secret ou PII aparece em logs
- Validar rastreabilidade pós-deploy (correlationId propagado, logs esperados emitidos)
- Verificar health checks e SLOs no ambiente alvo

## Flows consumidores

| Flow | Momento de uso |
|---|---|
| Hack | Step 5 — Validate observability (após Green Bar) |
| Validate | Observability Validation, SLO Validation, Incident Signals |
| Promote | Operational Evidence |

## Artefatos produzidos

- Logs estruturados com campos obrigatórios
- Métricas de negócio em `src/observability/metrics.ts`
- Health check em `/health`
- Evidência de observabilidade no Release Trail

## Documentação canônica

→ [prodops/framework/journeys/delivery/capabilities/observability-policy.md](observability-policy.md)
