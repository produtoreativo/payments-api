# EXP-016 — Baseline: Preparação para Feature #79

**Data:** 2026-07-29  
**Correlation-ID:** `9b17760f-e1f1-43b0-9f3d-08797f769531`  
**Branch:** `release/operational-flow-validation`  
**Commit HEAD:** `3cef1c0e44ace4d940a58fb55d92ed38afd0679c`

---

## Estado da Feature #79 (pré-execução)

| Campo | Valor |
|-------|-------|
| Issue | #79 — FTR-004: Split Payment — Conflito durante Sync |
| GitHub state | OPEN |
| Labels | journey:delivery, pilot:fase-2, feature:exception |
| Timeline #79 | Nenhum evento (timeline inexistente) |
| Derived State #79 | Nenhum (inexistente) |
| oem-state no Project | Não definido (não está como item do projeto com oem-state) |

---

## Runtime Doctor

```
Result: PASS (13/13)
```

---

## Estado do Iteration Plan IP-001

### Sequência obrigatória

| Feature | Issue | Promote.Completed | Derived State | Status |
|---------|-------|-----------------|---------------|--------|
| F-01 — Invoice PIX | #76 | ✓ (2× eventos) | DONE | ✓ Concluída |
| F-02 — Invoice Cartão | #77 | ✓ (1 evento) | DONE | ✓ Concluída |
| F-03 — Confirmação Pagamento | #78 | ✗ AUSENTE | HACKING | ✗ Incompleta |
| F-04 — Split Payment Conflito | #79 | n/a | n/a | **BLOQUEADA** |

### Timeline de F-03 (Issue #78)

```json
[
  "prodops.delivery.bootstrap.started",
  "prodops.delivery.bootstrap.completed",
  "prodops.delivery.hack.started"
]
```

**F-03 está em estado `HACKING` — sem `Hack.Completed`, `Sync`, `Finish.Completed` ou `Promote.Completed`.**

---

## Catálogo de Eventos — relevante para F-04

### Presentes no catálogo

```
Delivery.Bootstrap.Started/Completed
Delivery.Hack.Started/Completed
Delivery.Sync.Started/Completed
Delivery.Finish.Started/Completed
Delivery.Ship.Started/Completed
Delivery.Validate.Started/Completed
Shared.Gate.Passed
Delivery.Promote.Started/Completed
```

### AUSENTE no catálogo

```
Delivery.Gate.Failed   ← exigido pela sequência do PI-PILOT-004
```

O catálogo atual tem `Shared.Gate.Passed` mas **não possui** `Delivery.Gate.Failed` nem qualquer variante `*.Gate.Failed`.

---

## Código atual — Split Payment

Nenhum arquivo de produto relacionado a Split Payment ou `PaymentCompositionService` existe em `api/src/`:

```bash
find api/src -name "*split*" -o -name "*Split*" -o -name "*composition*"
# Resultado: vazio
```

---

## Precondições de F-04 (Iteration Plan IP-001)

| # | Precondição | Status |
|---|-------------|--------|
| 1 | Gate de Bloco satisfeito (F-01, F-02, F-03 com Promote.Completed) | ✗ **F-03 sem Promote.Completed** |
| 2 | `Finish.Completed` de F-03 presente na Timeline | ✗ **AUSENTE** |
| 3 | DQ-02 respondida (Event Type para Gate.Failed confirmado) | ✗ **Não respondida** |
| 4 | Branch `feature/pilot-split-payment-sync` criada de master | ✗ **Não criada** |

---

## Dashboard e Observabilidade

| Sistema | URL | Status |
|---------|-----|--------|
| Datadog Executive | https://app.datadoghq.com/dashboard/4rs-983-e35 | Disponível |
| GitHub Project | https://github.com/orgs/produtoreativo/projects/25 | Disponível |

---

## ⛔ BLOCKER — Journey não pode iniciar

**Razão 1 — Precondição do Iteration Plan não satisfeita:**

O Iteration Plan IP-001 estabelece:
> "A próxima Feature somente pode iniciar após `Delivery.Finish.Completed` da Feature anterior estar registrado na Timeline."

F-03 (Issue #78) não tem `Finish.Completed`. A Timeline de #78 contém apenas `Bootstrap.Started`, `Bootstrap.Completed` e `Hack.Started`. F-04 está bloqueada por este gate.

**Razão 2 — Event Type `Delivery.Gate.Failed` ausente do catálogo:**

A sequência de eventos do PI-PILOT-004 requer `Delivery.Gate.Failed` durante o Sync. Este event type **não existe** no catálogo atual (`prodops/runtime/catalog/events.yaml`). A DQ-02 ("Event Type para Gate.Failed de conflito confirmado") permanece em aberto.

Se a Tool `prodops_emit_event` fosse invocada com `event: "Delivery.Gate.Failed"`, retornaria erro de validação (catalog rejection).

---

## Ações necessárias antes de iniciar F-04

1. **Completar F-03** — executar a Journey de Issue #78 até `Finish.Completed` (mínimo) ou `Promote.Completed` (para satisfazer o Gate de Bloco)
2. **Responder DQ-02** — definir e adicionar ao catálogo o Event Type para `Gate.Failed` de conflito Sync, ou documentar que `Delivery.Gate.Failed` não é necessário e a Feature usará outro mecanismo
3. **Criar branch** — `feature/pilot-split-payment-sync` a partir de `master`

**Nenhum evento foi emitido para a Issue #79.**  
**A Journey da Feature #79 não foi iniciada.**
