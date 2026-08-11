# Context Capsule — DS-62 chargeback-handling

**ds-id:** DS-62
**work-item-id:** 173
**iteration-id:** v0.15.0
**correlation-id:** 3a2fbee7-74b4-4f3a-bfe6-561ea8322632
**slug:** chargeback-handling
**feature-branch:** feat/173-chargeback-handling
**base-branch:** master
**status:** finishing
**created-at:** 2026-08-11T00:00:00Z

## Paths

- OBC: `prodops/artifacts/obcs/chargeback-handling.md`
- BDD: `prodops/artifacts/bdd/chargeback-handling.feature`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-CB-001, RISK-CB-002)
- Release Trail: `prodops/artifacts/trails/sessions/2026-08-11-3a2fbee7.md`

## BDD Scenarios (6)

1. Chargeback solicitado pelo portador → CHARGEBACK_REQUESTED
2. Chargeback em fase de disputa → CHARGEBACK_DISPUTE
3. Aguardando reversão → CHARGEBACK_REVERSAL_PENDING
4. Webhook duplicado → idempotente
5. billingType errado → ignorado
6. Out-of-order DISPUTE sem REQUESTED → aceito
