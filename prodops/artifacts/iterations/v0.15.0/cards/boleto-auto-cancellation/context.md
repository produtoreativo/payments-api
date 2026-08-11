# Context Capsule — DS-63 boleto-auto-cancellation

**ds-id:** DS-63
**work-item-id:** 174
**iteration-id:** v0.15.0
**correlation-id:** 2fb61a10-9edc-44c4-94ff-31758371a6f1
**slug:** boleto-auto-cancellation
**feature-branch:** feat/174-boleto-auto-cancellation
**base-branch:** master
**status:** ready
**created-at:** 2026-08-11T00:00:00Z

## Paths

- OBC: `prodops/artifacts/obcs/boleto-auto-cancellation.md`
- BDD: `prodops/artifacts/bdd/boleto-auto-cancellation.feature`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-BC-001, RISK-BC-002)

## BDD Scenarios (6)

1. Boleto vencido → EXPIRED + payment.boleto.expired
2. Boleto criado com daysAfterDueDateToRegistrationCancellation=1
3. PAYMENT_OVERDUE duplicado → idempotente
4. CONFIRMED imune → não expira
5. billingType errado → ignorado
6. Valor padrão daysAfterDueDateToRegistrationCancellation=1
