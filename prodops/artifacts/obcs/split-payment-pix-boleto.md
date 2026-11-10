# OBC — Split Payment: Pix + Boleto

<!-- Owner: Eugenio (PM) + Tech Lead do produto -->
<!-- Business Intent: prodops/artifacts/business-intents/PI-001.md -->
<!-- Business Signal: prodops/artifacts/business-signals/BS-001.md -->

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-61 |
| Iteração | v0.13.0 (revisão em v0.14.0) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-61 (#160) — v0.13.0 (revisão em v0.14.0), PR #162 e PR #169. Registro anterior: Committed. Aprovado por Eugenio (PM) em 2026-08-04. Originado em `PI-001`. ---
**Pendência:** iteração concluída (PR #162 e PR #169); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-001](../business-signals/BS-001.md) |
| Business Intent | [PI-001](../business-intents/PI-001.md) |
| Product Tracking Item | issue #160 (DS-61), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

Clientes da Magazine Siará conseguem pagar uma mesma compra dividindo o valor entre **Pix e Boleto**. O pedido é confirmado e liberado somente quando **ambos** os pagamentos forem realizados. Enquanto apenas um dos meios estiver pago, o pedido permanece em estado pendente — visível para investigação manual pela operação.

O sistema garante rastreabilidade completa de cada porção do pagamento independentemente, permitindo que atendimento e operação identifiquem o estado exato de qualquer pedido Split pelo `orderId`, `splitPaymentId`, `pixInvoiceId` ou `boletoInvoiceId`.

### Em linguagem executiva

É como dividir uma conta de restaurante: cada pessoa paga a sua parte. O pedido só sai da cozinha quando todas as partes foram pagas. Se alguém não pagou, o garçom segura o pedido e avisa o responsável — não cancela automaticamente.

---

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/split-payment-pix-boleto.feature`; marcar após verificação.

- [ ] Criar Split Payment com sucesso
- [ ] Pedido liberado após confirmação dos dois meios
- [ ] Confirmação na ordem inversa — Boleto antes do Pix
- [ ] Retentativa de criação com mesma chave de idempotência
- [ ] Webhook duplicado de confirmação do Pix
- [ ] Boleto vence com Pix já confirmado
- [ ] Boleto vence sem nenhum pagamento realizado
- [ ] Rejeitar Split Payment com soma de valores incorreta
- [ ] Falha transiente ao criar cobrança no provedor
- [ ] Nenhum dado financeiro exposto em resposta de erro

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [split-payment-pix-boleto](../product/context/service-decks/split-payment-pix-boleto.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Significado | Dimensões obrigatórias |
|---|---|---|---|
| `split_payment.created` | Emitido | Split Payment criado com Pix e Boleto definidos | `splitPaymentId`, `orderId`, `pixAmount`, `boletoAmount`, `totalAmount`, `correlationId` |
| `split_payment.pix.confirmed` | Emitido | Porção Pix confirmada pelo provedor | `splitPaymentId`, `orderId`, `pixInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.boleto.confirmed` | Emitido | Porção Boleto confirmada pelo provedor | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.completed` | Emitido | Ambas as porções confirmadas — pedido liberado | `splitPaymentId`, `orderId`, `completedAt`, `correlationId` |
| `split_payment.boleto.expired` | Emitido | Boleto venceu sem pagamento — pedido pendente para investigação manual | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `expiredAt`, `pixStatus`, `correlationId` |
| `split_payment.creation_failed` | Emitido | Falha na criação do Split Payment | `orderId`, `reason`, `correlationId` |

---

## Initial SLIs

| SLI | Meta inicial | Fonte |
|---|---|---|
| Criação de Split Payment com mesma chave de idempotência retorna o mesmo resultado | 100% | [apurar] |
| Evento `split_payment.completed` emitido em até 5s após confirmação do segundo meio | 99% | [apurar] |
| Evento `split_payment.boleto.expired` emitido em até 60min após vencimento do Boleto | 99% | [apurar] |
| Pedido nunca liberado com apenas uma das porções confirmadas | 100% | [apurar] |
| `splitPaymentId` único por combinação de `orderId` + meios de pagamento | 100% | [apurar] |

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
- [ ] Prazo máximo para estado `PENDING_INVESTIGATION` (a definir com operação antes do go-live)
- [x] ~~Política para Boleto vencido com Pix pago~~ → mantém pendente com prazo máximo, investigação manual. Decidido em 2026-08-04.
- [x] ~~Interface no Checkout~~ → Checkout é responsabilidade de outro time; este time entrega apenas a API com Response Contract e Observable Events documentados.
- [x] ~~Times envolvidos além do Payments~~ → Checkout (outro time, consome a API) e Notification (outro time, reage aos Observable Events). Escopo do time de Payments: API apenas.
- [x] ~~Requisitos técnicos do fornecedor~~ → fornecedor fornece apenas mercadoria; sem requisitos técnicos. Fechado em 2026-08-04.

---

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |
| Serviço externo | Asaas (PSP) | Crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- Business Intent: `prodops/artifacts/business-intents/PI-001.md`
- Business Signal: `prodops/artifacts/business-signals/BS-001.md`
- BDD: `prodops/artifacts/bdd/split-payment-pix-boleto.feature` *(a criar)*
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md` *(a atualizar)*
- Service Deck: `prodops/artifacts/product/context/service-decks/split-payment-pix-boleto.md`
