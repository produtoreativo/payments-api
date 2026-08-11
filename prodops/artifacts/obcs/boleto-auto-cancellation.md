# OBC — Boleto Auto-Cancellation

**DS-ID:** DS-63
**Iteration:** v0.15.0
**Status:** committed
**Last updated:** 2026-08-11

---

## 1. Observable Behavior Contract

O sistema deve cancelar automaticamente boletos vencidos após 1 dia da data de vencimento, publicando o evento de expiração correspondente.

### Trigger

Webhook POST em `/webhook/payments` com `event` igual a `PAYMENT_OVERDUE` para uma invoice com `billingType = BOLETO`.

### Pre-conditions

- Invoice com `paymentId` correspondente deve existir.
- `billingType` da invoice deve ser `BOLETO`.
- Invoice não deve estar no status `CONFIRMED` (pagamentos confirmados são ignorados).

### Behavior

Quando uma invoice BOLETO recebe o evento `PAYMENT_OVERDUE`:
1. O status é transitado para `EXPIRED`.
2. O evento de domínio `payment.boleto.expired` é publicado para os consumidores.

### Configuration

| Campo | Valor padrão (mercado) |
|---|---|
| `daysAfterDueDateToRegistrationCancellation` | `1` — boleto cancelado 1 dia após vencimento |

### Business Rules

1. **Apenas BOLETO**: webhooks `PAYMENT_OVERDUE` para outros `billingType` são ignorados sem erro.
2. **Idempotência**: receber `PAYMENT_OVERDUE` para um boleto já `EXPIRED` é no-op.
3. **CONFIRMED imune**: se a invoice já está `CONFIRMED`, o webhook é ignorado — pagamento confirmado prevalece.
4. **Padrão de mercado**: `daysAfterDueDateToRegistrationCancellation=1` é o padrão Asaas para cancelamento automático.

### Observable Events

| Evento | Condição |
|---|---|
| `payment.boleto.expired` | Transição para `EXPIRED` bem-sucedida |

---

## 2. SLO

| Indicador | Meta |
|---|---|
| Eventos publicados dentro de 5s após webhook recebido | 99,9% |
| Idempotência em duplicate webhooks | 100% |
| Boletos CONFIRMED nunca transitados para EXPIRED | 100% |

---

## 3. Referências

- BDD: `prodops/artifacts/bdd/boleto-auto-cancellation.feature`
- Risks: `prodops/artifacts/risks/risks.md` (RISK-BC-001, RISK-BC-002)
- GitHub Issue: #174
