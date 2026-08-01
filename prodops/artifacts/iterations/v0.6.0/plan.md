# Iteration Plan — v0.6.0 (Ativo)

> Status: 🔄 Em andamento

## Escopo

| DS | Issue | Feature | Dependência | OBC | BDD | E2E | Status |
|---|---|---|---|---|---|---|---|
| DS-39 | [#106](https://github.com/produtoreativo/payments-api/issues/106) | payment-confirmation: confirmar pagamento aprovado via webhook do provedor | — | ✓ | ✓ | ✓ | Entrou |
| DS-42 | [#107](https://github.com/produtoreativo/payments-api/issues/107) | api-token-validation: garantir acesso autenticado por token de API | — | ✓ | ✓ | ✓ | Entrou |
| DS-43 | [#108](https://github.com/produtoreativo/payments-api/issues/108) | webhook-configuration: configurar webhook de notificação por token de API | DS-42 | ✓ | ✓ | ✓ | Entrou |
| DS-41 | [#109](https://github.com/produtoreativo/payments-api/issues/109) | credit-card-authorization-confirmation: aceitar pagamento com cartão de crédito hospedado | — | ✓ | ✓ | ✓ | Entrou |

## Mapeamento DS-ID → Issue

| DS-ID | Feature slug | Issue v0.6.0 | Issue v0.5.0 (ref) |
|---|---|---|---|
| DS-39 | payment-confirmation | #106 | #39 |
| DS-42 | api-token-validation | #107 | #42 |
| DS-43 | webhook-configuration | #108 | #43 |
| DS-41 | credit-card-authorization-confirmation | #109 | #41 |

## Critérios de saída

- [ ] PRs merged em `main` para cada issue (#106, #107, #108, #109)
- [ ] `prodops.delivery.promote.completed` emitido para issues #106, #107, #108, #109
- [ ] KPI Lead Time calculável: `Bootstrap.Started` presente nos timelines de cada issue
- [ ] Issues #106, #107, #108, #109 fechadas no GitHub
- [ ] Diligence concluída para cada item: evidence capturada, attached, promoted e closed

## Runtime

- Iteration dir: `prodops/artifacts/iterations/v0.6.0/`
- Timelines: `runtime/timelines/<issue>.json`
- Plan Bootstrap: `runtime/plan-bootstrap.json`
- Plan Validate: `runtime/plan-validate.json`
- Context capsules: `cards/<slug>/context.md`
- Session trails: `trails/`
