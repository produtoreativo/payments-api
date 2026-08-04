# OBC — Split Payment: Pix + Boleto

<!-- Owner: Eugenio (PM) + Tech Lead do produto -->
<!-- Business Intent: prodops/artifacts/business-intents/PI-001.md -->
<!-- Business Signal: prodops/artifacts/business-signals/BS-001.md -->

## Status

Committed. Aprovado por Eugenio (PM) em 2026-08-04. Originado em `PI-001`.

---

## Business Outcome

Clientes da Magazine Siará conseguem pagar uma mesma compra dividindo o valor entre **Pix e Boleto**. O pedido é confirmado e liberado somente quando **ambos** os pagamentos forem realizados. Enquanto apenas um dos meios estiver pago, o pedido permanece em estado pendente — visível para investigação manual pela operação.

O sistema garante rastreabilidade completa de cada porção do pagamento independentemente, permitindo que atendimento e operação identifiquem o estado exato de qualquer pedido Split pelo `orderId`, `splitPaymentId`, `pixInvoiceId` ou `boletoInvoiceId`.

### Em linguagem executiva

É como dividir uma conta de restaurante: cada pessoa paga a sua parte. O pedido só sai da cozinha quando todas as partes foram pagas. Se alguém não pagou, o garçom segura o pedido e avisa o responsável — não cancela automaticamente.

---

## Observable Events

| Event | Significado | Dimensões obrigatórias |
|---|---|---|
| `split_payment.created` | Split Payment criado com Pix e Boleto definidos | `splitPaymentId`, `orderId`, `pixAmount`, `boletoAmount`, `totalAmount`, `correlationId` |
| `split_payment.pix.confirmed` | Porção Pix confirmada pelo provedor | `splitPaymentId`, `orderId`, `pixInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.boleto.confirmed` | Porção Boleto confirmada pelo provedor | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.completed` | Ambas as porções confirmadas — pedido liberado | `splitPaymentId`, `orderId`, `completedAt`, `correlationId` |
| `split_payment.boleto.expired` | Boleto venceu sem pagamento — pedido pendente para investigação manual | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `expiredAt`, `pixStatus`, `correlationId` |
| `split_payment.creation_failed` | Falha na criação do Split Payment | `orderId`, `reason`, `correlationId` |

---

## Initial SLIs

| SLI | Meta inicial |
|---|---|
| Criação de Split Payment com mesma chave de idempotência retorna o mesmo resultado | 100% |
| Evento `split_payment.completed` emitido em até 5s após confirmação do segundo meio | 99% |
| Evento `split_payment.boleto.expired` emitido em até 60min após vencimento do Boleto | 99% |
| Pedido nunca liberado com apenas uma das porções confirmadas | 100% |
| `splitPaymentId` único por combinação de `orderId` + meios de pagamento | 100% |

---

## Reliability Rules

- **Idempotência:** a criação de Split Payment com o mesmo `orderId` e mesma configuração de meios deve retornar o mesmo `splitPaymentId` — retentativas não criam cobranças duplicadas.
- **Liberação somente com ambas as porções:** o pedido nunca é liberado com apenas Pix ou apenas Boleto confirmado. A transição para `completed` exige confirmação dos dois meios.
- **Boleto vencido com Pix pago:** o sistema **não cancela automaticamente** nem estorna o Pix. O estado passa para pendente e o evento `split_payment.boleto.expired` é emitido com `pixStatus: confirmed` para sinalizar à operação que há investigação manual necessária.
- **Soma dos valores:** `pixAmount + boletoAmount` deve ser igual ao `totalAmount` do pedido — validado antes de qualquer chamada ao provedor externo.
- **Isolamento de falha:** falha no provedor de um dos meios não deve afetar o estado do outro meio já confirmado.
- **Auditoria:** `splitPaymentId`, `orderId`, `pixInvoiceId` e `boletoInvoiceId` presentes em todos os logs. Dados financeiros (valores, status) nunca expostos em respostas de erro públicas.

---

## Response Contract

```json
{
  "splitPaymentId": "spl_abc123",
  "orderId": "ord_xyz789",
  "status": "PENDING_BOTH | PIX_CONFIRMED | BOLETO_CONFIRMED | COMPLETED | PENDING_INVESTIGATION",
  "totalAmount": 500.00,
  "pix": {
    "invoiceId": "pix_111",
    "amount": 200.00,
    "status": "PENDING | CONFIRMED",
    "confirmedAt": null
  },
  "boleto": {
    "invoiceId": "bol_222",
    "amount": 300.00,
    "dueDate": "2026-08-19",
    "status": "PENDING | CONFIRMED | EXPIRED",
    "confirmedAt": null
  },
  "createdAt": "2026-08-04T00:00:00Z",
  "completedAt": null
}
```

---

## Decisões explícitas

| Decisão | Racional |
|---|---|
| Boleto vencido mantém pedido pendente com prazo máximo | Decidido por Eugenio (PM) em 2026-08-04. Não cancela nem estorna automaticamente. Operação investiga manualmente dentro de prazo máximo a definir antes do go-live. Política revisada em Assessment após 30 dias em produção. |
| Cartão de crédito fora do escopo | Entra em fase posterior ao lançamento com o fornecedor parceiro. |
| Limite de meios por compra: 2 | Pix + Boleto apenas. Combinações adicionais fora deste OBC. |

---

## Perguntas em aberto

- [ ] Valor mínimo e máximo permitido por porção de pagamento
- [ ] Política definitiva para Boleto vencido com Pix pago (cancelar + estornar vs. reemitir Boleto vs. manter pendente)
- [ ] Interface no Checkout para o cliente definir a divisão dos valores
- [ ] Times envolvidos além do Payments: Checkout, Notification Service

---

## Related Artifacts

- Business Intent: `prodops/artifacts/business-intents/PI-001.md`
- Business Signal: `prodops/artifacts/business-signals/BS-001.md`
- BDD: `prodops/artifacts/bdd/split-payment-pix-boleto.feature` *(a criar)*
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` *(a atualizar)*
