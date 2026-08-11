# OBC — Chargeback Handling

**DS-ID:** DS-62
**Iteration:** v0.15.0
**Status:** committed
**Last updated:** 2026-08-11

---

## 1. Observable Behavior Contract

O sistema deve rastrear e publicar eventos de chargeback recebidos do PSP Asaas, transitando o estado da invoice sem executar nenhuma ação financeira autônoma.

### Trigger

Webhook POST em `/webhook/payments` com `event` igual a:
- `PAYMENT_CHARGEBACK_REQUESTED`
- `PAYMENT_CHARGEBACK_DISPUTE`
- `PAYMENT_AWAITING_CHARGEBACK_REVERSAL`

### Pre-conditions

- Invoice com `paymentId` correspondente deve existir.
- `billingType` da invoice deve ser `CREDIT_CARD`.

### Mappings

| PSP Event (`event`) | InvoiceStatus | Domain Event emitido |
|---|---|---|
| `PAYMENT_CHARGEBACK_REQUESTED` | `CHARGEBACK_REQUESTED` | `payment.chargeback_requested` |
| `PAYMENT_CHARGEBACK_DISPUTE` | `CHARGEBACK_DISPUTE` | `payment.chargeback_dispute` |
| `PAYMENT_AWAITING_CHARGEBACK_REVERSAL` | `CHARGEBACK_REVERSAL_PENDING` | `payment.chargeback_reversal_pending` |

### Business Rules

1. **Apenas CREDIT_CARD**: webhooks de chargeback para outros `billingType` são ignorados sem erro (idempotent no-op).
2. **Idempotência**: receber o mesmo evento duas vezes resulta em no-op se o `status` já é o esperado.
3. **Out-of-order aceito**: `CHARGEBACK_DISPUTE` pode chegar sem `CHARGEBACK_REQUESTED` anterior.
4. **Sem ação financeira**: o sistema apenas rastreia e publica o evento; nenhum reembolso, estorno ou freeze é executado automaticamente.

### Observable Events

| Evento | Condição |
|---|---|
| `payment.chargeback_requested` | Transição para `CHARGEBACK_REQUESTED` bem-sucedida |
| `payment.chargeback_dispute` | Transição para `CHARGEBACK_DISPUTE` bem-sucedida |
| `payment.chargeback_reversal_pending` | Transição para `CHARGEBACK_REVERSAL_PENDING` bem-sucedida |

---

## 2. SLO

| Indicador | Meta |
|---|---|
| Eventos publicados dentro de 5s após webhook recebido | 99,9% |
| Idempotência mantida em duplicate webhooks | 100% |

---

## 3. Referências

- BDD: `prodops/artifacts/bdd/chargeback-handling.feature`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-CB-001, RISK-CB-002)
- GitHub Issue: #173
