# Product Intent — PI-PILOT-004

> **Localização canônica:** `prodops/artifacts/business-intents/PI-PILOT-004.md`
>
> Uma **Product Intent** registra uma decisão estratégica de perseguir valor em um produto específico — nascida de um Business Signal. Não é um compromisso de implementação.

---

## Identificação

| Campo | Conteúdo |
|---|---|
| **Identificador** | `PI-PILOT-004` |
| **Título** | Split Payment — Conflito Durante Sync |
| **Origin Stream** | Team · Technology |
| **Data de registro** | 2026-07-26 |
| **Business Signal de origem** | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) |
| **Produto** | payments-api |
| **Dono de produto** | Tech Lead Payments |
| **Status** | Em Discovery |
| **Release candidata** | [REL-PILOT-v1](../product/release-draft-pilot.md) |

---

## Objetivo

Registrar e validar o padrão de conflito durante a fase Sync de uma Feature de Split Payment no ProdOps Runtime — exercitando o mecanismo de Gate.Failed e confirmando que o OEM suporta o padrão de conflito detectado na sincronização sem necessidade de conceito novo.

> "Queremos que a Feature de Split Payment, quando encontrar um conflito durante o Sync (dois pagamentos parciais em estado inconsistente), registre o Gate.Failed na Timeline e derive o Derived State correto — confirmando que o OEM suporta conflito como Event Instance rastreável."

---

## Hipótese

> **Um conflito de conciliação durante a fase Sync (dois pagamentos parciais em estado inconsistente de composição) pode ser representado no OEM usando `Delivery.Gate.Failed` com payload descritivo, sem necessidade de um novo Shared Type ou Event Type para conflito de Sync.**

---

## Escopo da Feature

### O que esta Feature entrega (domínio de Payments)

Implementação do fluxo de Split Payment (composição de dois meios de pagamento — ex.: PIX + Cartão) com o cenário em que, durante a fase Sync, os dois pagamentos parciais chegam a estados inconsistentes: um confirmado e outro ainda pendente, criando um conflito de conciliação no `PaymentCompositionService`.

A Feature entrega o mecanismo de detecção do conflito e a resposta correta do sistema (nenhum valor processado enquanto o conflito não for resolvido).

### Padrão ProdOps exercitado

| Padrão | Exercitado? |
|---|---|
| Happy Path completo | ❌ — o conflito ocorre no Sync e bloqueia a progressão normal |
| Gate.Failed durante Sync | ✅ **Foco primário** — o conflito é representado como Gate.Failed |
| Gate.Passed após resolução | ✅ — após resolução manual, gate é retestado |
| Rework | ❌ — conflito resolvido sem retorno ao Hack nesta Feature |
| Blocking (Impediment) | ❌ — o conflito é um gate, não um impedimento externo |

### Sequência de eventos esperada na Timeline

```
Delivery.Bootstrap.Started
Delivery.Hack.Started
Delivery.Hack.Completed
Delivery.Sync.Started
Delivery.Gate.Failed          (conflito: PIX confirmado, Cartão pendente — inconsistência detectada)
  payload: {
    reason: "composição inconsistente — pagamento parcial #1 confirmado, #2 pendente",
    composition_id: "<compositionId>",
    conflicting_invoice_ids: ["<id1>", "<id2>"]
  }
Delivery.Gate.Passed          (conflito resolvido — composição reconciliada)
Delivery.Sync.Completed
Delivery.Finish.Started
Delivery.Finish.Completed
Delivery.Ship.Started
Delivery.Ship.Completed
Delivery.Validate.Started
Delivery.Gate.Passed
Delivery.Validate.Completed
Delivery.Promote.Started
Delivery.Promote.Completed
```

---

## Valor esperado

### Para o piloto operacional

- Primeira evidência de `Gate.Failed` real em Timeline de Work Item
- Confirmação de que conflito de Sync é representável sem novo Event Type
- Baseline de Cycle Time para Features de Split Payment (mais longo que happy path por conta do gate)

### Para o produto (payments-api)

- Feature de Split Payment com mecanismo de conflito rastreável e auditável
- Histórico: conflito detectado em `<timestamp>`, resolvido em `<timestamp>`, tempo de resolução mensurável

---

## Critérios de sucesso

1. `Gate.Failed` registrado na Timeline com payload que identifica o conflito de forma rastreável
2. Após resolução, `Gate.Passed` registrado e Sync continuado
3. Timeline completa até `Promote.Completed`
4. Derived State correto em cada ponto — incluindo o estado intermediário durante o conflito
5. Nenhum Event Type novo foi necessário para representar o conflito de Sync

---

## Modo de execução

- [x] **Upstream** — validação de hipótese antes de OBC

---

## Perguntas em aberto

- [ ] O payload do `Gate.Failed` para conflito de Sync deve referenciar os IDs internos da composição ou apenas descrever o tipo de conflito?
- [ ] O Derived State durante um `Gate.Failed` (sem resolução ainda) mantém o Work Item em SYNCING ou transiciona para algum estado intermediário?
- [ ] O catálogo Delivery v2 contém `Delivery.Gate.Failed` como Event Type explícito, ou é inferido pelo padrão `*.Gate.Failed`?

---

## Relação com EXP-007

Este Work Item utiliza o domínio de Split Payment explorado em [EXP-007](../experiments/007-split-payment-model/experiment.md). A Feature não implementa o modelo completo de `PaymentComposition` definido no EXP-007 — implementa o subconjunto necessário para exercitar o padrão de conflito no Runtime.

---

## Artefatos gerados

| Artefato | Localização | Status |
|---|---|---|
| Business Signal | [BS-PILOT-001](../business-signals/BS-PILOT-001.md) | Criado |
| Release Draft | [release-draft-pilot.md](../product/release-draft-pilot.md) | Criado |
| Timeline de execução | `prodops/artifacts/experiments/013-runtime-validation/evidence/` | A criar na execução |
