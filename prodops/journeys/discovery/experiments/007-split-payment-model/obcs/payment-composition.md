# OBC — Composição de Pagamento (Draft)

> Status: **Draft — aguarda decisão de política de falha parcial**
> Localização: `prodops/journeys/discovery/experiments/007-split-payment-model/obcs/payment-composition.md`
> Experimento de origem: `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
> Promover via: `/upstream move-to-downstream` após decisão de produto

---

## Observable Business Contract

### Outcome

> Cliente consegue concluir um pedido usando 2 métodos de pagamento, recebendo confirmação agregada após todos os métodos serem processados.

### Observable

| SLI | Medida | SLO | Janela |
|---|---|---|---|
| Latência de criação de composição | p99 de `POST /v1/payment-compositions` | < 800ms | Rolling 24h |
| Confirmação agregada | Tempo entre criação e `PagamentoCompostoConfirmado` | < 5 min em 95% dos casos | Rolling 7d |
| Estorno total após falha | Tempo entre `PagamentoParcialFalhou` e estorno dos métodos confirmados | < 30s em 99% | Rolling 7d |
| Disponibilidade do endpoint de composição | Taxa de sucesso 2xx em `POST /v1/payment-compositions` | ≥ 99.5% | Rolling 30d |

---

## Precondições

- Cliente autenticado com `X-Api-Token` válido
- `orderId` existe e está em estado elegível para pagamento
- `totalAmount` = soma de `methods[].amount`
- Cada método tem `billingType` válido (PIX, CREDIT_CARD)
- Combinação de métodos permitida pela política de MVP (máx. 2 métodos; pelo menos um de confirmação imediata)

---

## Postcondições

**Sucesso (composição confirmada):**
- `PaymentComposition.compositionStatus` = `CONFIRMED`
- `confirmedAmount` = `totalAmount`
- Evento `PagamentoCompostoConfirmado` emitido com `compositionId`, `orderId`, `totalAmount`, `methods[]`
- Order Management notificado

**Falha parcial — Política B (recomendada):**
- Método confirmado permanece em `CONFIRMED`
- `PaymentComposition.compositionStatus` = `PARTIALLY_FAILED`
- Evento `PagamentoParcialFalhou` emitido
- Cliente pode substituir método falho sem perder método confirmado

**Falha total:**
- Todos os métodos falham → `FAILED`
- Nenhum estorno necessário (nenhum método chegou a `CONFIRMED`)
- Evento `PagamentoCompostoFalhou` emitido

---

## Reliability Rules

| Regra | Critério |
|---|---|
| Idempotência | Mesma `compositionId` não cria novo estado nem novas invoices se recebida novamente |
| Idempotência de webhook | Webhook duplicado do Asaas não dispara evento duplicado de `PagamentoParcialConfirmado` |
| Expiração | Composição sem confirmação total em `X minutos` (a definir pelo produto) entra em `EXPIRED` |
| Atomicidade de estorno | Estorno de composição cancela TODAS as invoices confirmadas ou nenhuma |
| Não regressão | Pagamento simples (sem `compositionId`) não é afetado por qualquer mudança da composição |

---

## Não coberto por este OBC

- Composição com mais de 2 métodos (pós-MVP)
- Boleto como método parcial (exige análise de janela de confirmação assíncrona)
- Composição com gift card / cashback (depende de entidade de saldo interno — escopo separado)
- Pagamento cross-tenant

---

## Modos de falha e mitigações

| Modo de falha | Probabilidade | Mitigação |
|---|---|---|
| Webhook out-of-order (Charge B confirmado antes de A) | Baixa | State machine idempotente; evento só emitido quando `allConfirmed` |
| Partial confirmation + cancelamento do pedido | Média | Contrato de cancelamento total deve incluir estorno de métodos confirmados |
| Asaas timeout no segundo charge | Média | Retry com backoff + evento `PagamentoParcialFalhou` após max retries |
| Divergência entre `confirmedAmount` e soma de invoices | Baixa | Validação no `PaymentCompositionService` antes de emitir `PagamentoCompostoConfirmado` |

---

## Decisão pendente de produto

| Questão | Opções | Status |
|---|---|---|
| Política de falha parcial | A (reverter tudo), B (manter confirmados), C (janela parcial) | **Pendente** |
| Janela de expiração | 5 min / 10 min / 30 min | **Pendente** |
| Combinações permitidas no MVP | Pix+Cartão apenas / Pix+Cartão+Boleto | **Recomendado: Pix+Cartão apenas** |

---

## Próximo passo após decisão

1. Preencher política de falha e janela de expiração acima
2. Criar BDD Feature: `prodops/journeys/discovery/experiments/007-split-payment-model/features/payment-composition.feature`
3. Executar `/upstream move-to-downstream` — moverá OBC e BDD Feature para `artifacts/`
4. Atualizar Iteration Plan para incluir Split Payment
5. Bootstrap → Hack

---

## Referências

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/artifacts/business/intents/split-payment.md`
