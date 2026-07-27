# Product Intent — PI-PILOT-003

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-003.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-003` |
| **Título** | Confirmação de Pagamento — Happy Path via Webhook |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o ciclo completo de entrega da Feature de Confirmação de Pagamento via webhook — confirmando que a ação de um sistema externo (provider webhook) pode ser representada na Timeline do OEM como um evento de sistema, e que o ciclo happy path cobre esse padrão assíncrono.

> "Queremos que a Feature de Confirmação de Pagamento — disparada por webhook do gateway — seja executada com Runtime completo, produzindo uma Timeline que inclua o evento de sistema de confirmação e derivando o Derived State final como DONE."

---

## Hipótese

> **A confirmação de pagamento assíncrona, disparada por webhook do provider externo, pode ser representada integralmente no OEM usando `Delivery.System.Completed` (ou event type equivalente do catálogo), sem necessidade de conceito novo para eventos externos.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Processamento do webhook de confirmação enviado pelo provider (Asaas ou equivalente): recepção do evento externo, validação da assinatura, tradução para o modelo canônico interno, publicação de `PagamentoConfirmado`, liberação da ordem. A Feature inclui o mecanismo de idempotência (reprocessamento de webhook duplicado não gera duplicidade de evento).

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path — Bootstrap.Started → Promote.Completed | ✅ Foco primário |
| Evento de Sistema na Timeline (`Delivery.System.*`) | ✅ — representação do webhook como evento |
| Gate.Passed / Gate.Failed | ✅ — gate de idempotência na fase Validate |
| Rework | ❌ — não exercitado nesta Feature |
| Blocking (Impediment) | ❌ — não exercitado nesta Feature |

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.System.Completed     (webhook recebido e processado — evento de sistema)
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed          (idempotência verificada)
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
```

---

## Valor esperado

### Para o piloto operacional

- Terceira e última Timeline do happy path — conclui o conjunto de evidências do caminho feliz
- Confirmação de que eventos de sistema externo (webhook) são representáveis no OEM sem loss de rastreabilidade
- Evidência de que o padrão assíncrono não quebra a propriedade de determinismo do Replay

### Para o produto (payments-api)

- Feature de Confirmação de Pagamento promovida com Timeline auditável — cada webhook que chegou está registrado
- Idempotência verificada e auditável na Timeline (não apenas em código)

---

## Critérios de sucesso

1. Timeline de `Bootstrap.Started` a `Promote.Completed` registrada com evento de sistema do webhook
2. Replay da Timeline após `System.Completed` deriva o mesmo estado que o cálculo incremental
3. `Gate.Passed` de idempotência registrado na fase Validate
4. Derived State calculado corretamente — DONE ao final
5. Nenhum Event Type novo foi necessário para representar o webhook no OEM

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] `Delivery.System.Completed` é o Event Type correto para representar o webhook de confirmação, ou o catálogo tem um tipo mais específico?
- [ ] Como registrar o `producer_identity` do evento de sistema — o provider externo é o producer, ou o handler interno da payments-api?

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
