# EXP-014 — Iteração 1: Diligence Tracks Delivery
# Relatório de Conclusão

**Data:** 2026-07-27T16:14Z–16:15Z
**Status:** ✅ COMPLETED — todos os critérios de sucesso atendidos
**Script:** `prodops/runtime/scripts/bootstrap-diligence.sh`
**runtime-version:** 0.3.0

---

## Respostas Objetivas

| Pergunta | Resposta |
|---|---|
| 1. A Diligence Journey rastreou o Delivery sem alterar seu estado? | **Sim** — DONE/VALIDATING/HACKING preservados após o ciclo completo |
| 2. Quantos Diligence CloudEvents foram emitidos? | **12** (4 por Feature × 3 Features) |
| 3. Todos os CloudEvents passaram nos dois gates de validação? | **Sim** — 12/12 PASS no producer e no timeline |
| 4. As timelines Diligence estão separadas das Delivery? | **Sim** — `timelines/diligence-76/77/78.json`, sem tocar em `76/77/78.json` |
| 5. Os CloudEvents Diligence contêm `delivery-correlation-id`? | **Sim** — `data.delivery-correlation-id` em todos os 12 eventos |
| 6. Os 3 campos GitHub foram criados e populados? | **Sim** — `diligence-status`, `diligence-evidence`, `runtime-sync` |
| 7. Estado final no GitHub para todos os 3 Issues? | `diligence-status=Attached`, `diligence-evidence=Complete`, `runtime-sync=In Sync` |
| 8. Datadog recebeu ambas as métricas? | **Sim** — 12 pontos `runtime.diligence.event.received` + 3 `runtime.diligence.features.tracked` |
| 9. Nenhuma credencial exposta? | **Sim** ✅ |

---

## Critérios de Sucesso — Estado Final

| Critério | Status |
|---|---|
| Delivery states preservados (DONE/VALIDATING/HACKING) | ✅ |
| 4 eventos Diligence por Feature | ✅ |
| CloudEvents contêm `delivery-correlation-id`, `delivery-last-event-type`, `delivery-derived-state` | ✅ |
| Timelines Diligence separadas (`timelines/diligence-{issue}.json`) | ✅ |
| Dois gates de validação CloudEvents passados (producer + timeline) | ✅ |
| 3 campos GitHub criados: `diligence-status`, `diligence-evidence`, `runtime-sync` | ✅ |
| `diligence-status=Attached` para #76, #77, #78 | ✅ |
| `diligence-evidence=Complete` para #76, #77, #78 | ✅ |
| `runtime-sync=In Sync` para #76, #77, #78 | ✅ |
| `runtime.diligence.event.received` — 12 pontos HTTP 202 | ✅ |
| `runtime.diligence.features.tracked` — 3 pontos HTTP 202 | ✅ |
| Catálogo expandido com 4 eventos Diligence | ✅ |
| Nenhuma credencial exposta | ✅ |

---

## Phase 1 — Delivery State Snapshot (pré-Diligence)

Estado lido de `derived-state-{issue}.json` — não modificado:

| Issue | Feature | Delivery State | Last Event Type | Delivery Correlation ID |
|---|---|---|---|---|
| #76 | FTR-001: Invoice PIX | **DONE** | `prodops.delivery.promote.completed` | `8c296acd-849b-49d4-a812-0fb186c673b7` |
| #77 | FTR-002: Invoice Cartão | **VALIDATING** | `prodops.delivery.validate.started` | `e63de2fc-a11b-445c-a433-7e735ce456ba` |
| #78 | FTR-003: Confirmação Pagamento | **HACKING** | `prodops.delivery.hack.started` | `e1eaf136-db1b-45ea-932b-7818d38f9620` |

Estes valores foram capturados **antes** do ciclo Diligence e confirmados **iguais** após sua conclusão.

---

## Phase 2 — Catálogo de Eventos (4 novos eventos Diligence)

Eventos adicionados a `prodops/runtime/catalog/events.yaml`:

| Logical Name | CE Type | Journey | Cycle | Phase | alters-state |
|---|---|---|---|---|---|
| `Diligence.Capture.Started` | `prodops.diligence.capture.started` | Diligence | Capture | Started | false |
| `Diligence.Capture.Completed` | `prodops.diligence.capture.completed` | Diligence | Capture | Completed | false |
| `Diligence.Attach.Started` | `prodops.diligence.attach.started` | Diligence | Attach | Started | false |
| `Diligence.Attach.Completed` | `prodops.diligence.attach.completed` | Diligence | Attach | Completed | false |

Todos com `alters-state: false` — o estado Diligence é gerenciado explicitamente no GitHub, não derivado automaticamente.

---

## Phase 3 — Diligence Correlation IDs

| Issue | Feature | Diligence Correlation ID | Delivery Correlation ID (referência) |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | `43abea46-37d6-4e57-9149-2f3f9bf75a5c` | `8c296acd-849b-49d4-a812-0fb186c673b7` |
| #77 | FTR-002: Invoice Cartão | `84f03bf5-4a06-40b1-bc12-bea558a500b9` | `e63de2fc-a11b-445c-a433-7e735ce456ba` |
| #78 | FTR-003: Confirmação Pagamento | `b9c09a76-a67c-4e49-bd8e-70b04664ebb1` | `e1eaf136-db1b-45ea-932b-7818d38f9620` |

---

## Phase 4 — Diligence CloudEvents por Feature

### FTR-001 (#76) — Delivery: DONE

| # | CloudEvent Type | Timestamp | Diligence Status |
|---|---|---|---|
| 1 | prodops.diligence.capture.started | 16:14:38Z | Sync In Progress |
| 2 | prodops.diligence.capture.completed | 16:14:40Z | Captured |
| 3 | prodops.diligence.attach.started | 16:14:45Z | Sync In Progress |
| 4 | prodops.diligence.attach.completed | 16:14:47Z | **Attached** |

### FTR-002 (#77) — Delivery: VALIDATING

| # | CloudEvent Type | Timestamp | Diligence Status |
|---|---|---|---|
| 1 | prodops.diligence.capture.started | 16:14:53Z | Sync In Progress |
| 2 | prodops.diligence.capture.completed | 16:14:54Z | Captured |
| 3 | prodops.diligence.attach.started | 16:15:00Z | Sync In Progress |
| 4 | prodops.diligence.attach.completed | 16:15:01Z | **Attached** |

### FTR-003 (#78) — Delivery: HACKING

| # | CloudEvent Type | Timestamp | Diligence Status |
|---|---|---|---|
| 1 | prodops.diligence.capture.started | 16:15:07Z | Sync In Progress |
| 2 | prodops.diligence.capture.completed | 16:15:09Z | Captured |
| 3 | prodops.diligence.attach.started | 16:15:14Z | Sync In Progress |
| 4 | prodops.diligence.attach.completed | 16:15:16Z | **Attached** |

---

## Phase 5 — CloudEvent Structure (sample — diligence-76.json[0])

```json
{
  "specversion": "1.0",
  "id": "597837b1-195a-4e8a-b175-d05889bc02ea",
  "source": "https://github.com/produtoreativo/payments-api",
  "type": "prodops.diligence.capture.started",
  "subject": "76",
  "time": "2026-07-27T16:14:38Z",
  "datacontenttype": "application/json",
  "dataschema": "https://prodops.produtoreativo.io/schemas/events/diligence/capture/started/v1.0.0",
  "data": {
    "issue": "76",
    "journey": "Diligence",
    "cycle": "Capture",
    "phase": "Started",
    "alters-state": false,
    "diligence-correlation-id": "43abea46-37d6-4e57-9149-2f3f9bf75a5c",
    "delivery-correlation-id": "8c296acd-849b-49d4-a812-0fb186c673b7",
    "delivery-last-event-type": "prodops.delivery.promote.completed",
    "delivery-derived-state": "DONE",
    "diligence-status": "Sync In Progress",
    "runtime-version": "0.3.0",
    "framework-version": "1.0.0",
    "schema-version": "1"
  }
}
```

**Campos de cross-referência Delivery → Diligence presentes em todos os 12 eventos:**
- `data.delivery-correlation-id` — aponta para o run de Delivery do EXP-013
- `data.delivery-last-event-type` — snapshot do último evento Delivery no momento do Capture
- `data.delivery-derived-state` — snapshot do Delivery state derivado no momento do Capture

---

## Phase 6 — Timelines Diligence (separadas, sem impacto nas Delivery)

| Timeline File | Events | CE Types |
|---|---|---|
| `timelines/diligence-76.json` | 4 | capture.started, capture.completed, attach.started, attach.completed |
| `timelines/diligence-77.json` | 4 | capture.started, capture.completed, attach.started, attach.completed |
| `timelines/diligence-78.json` | 4 | capture.started, capture.completed, attach.started, attach.completed |
| `timelines/76.json` | 15 | **inalterado** — Delivery only |
| `timelines/77.json` | 11 | **inalterado** — Delivery only |
| `timelines/78.json` | 3 | **inalterado** — Delivery only |

Todos os 12 CloudEvents Diligence passaram nos dois gates de validação:
- **Gate 1 (producer):** `validate-event.sh` PASS antes de sair do produtor
- **Gate 2 (timeline):** `validate-event.sh` PASS novamente antes de persistir na timeline

---

## Phase 7 — GitHub Project — Campos Diligence

Lido via GraphQL após execução — não presumido:

| Issue | `diligence-status` | `diligence-evidence` | `runtime-sync` | `oem-state` (Delivery, inalterado) |
|---|---|---|---|---|
| #76 | **Attached** | **Complete** | **In Sync** | DONE |
| #77 | **Attached** | **Complete** | **In Sync** | VALIDATING |
| #78 | **Attached** | **Complete** | **In Sync** | HACKING |

**3 novos campos criados automaticamente pelo script (via `gh project field-create`):**
- `diligence-status` (SingleSelect): Pending, Sync In Progress, Captured, Attached
- `diligence-evidence` (SingleSelect): Missing, Partial, Complete
- `runtime-sync` (SingleSelect): Pending, In Sync

**Progressão observada por Feature:**
1. Após `Capture.Completed`: `diligence-status=Captured`, `diligence-evidence=Partial`, `runtime-sync=Pending`
2. Após `Attach.Completed`: `diligence-status=Attached`, `diligence-evidence=Complete`, `runtime-sync=In Sync`

**GitHub Project:** https://github.com/orgs/produtoreativo/projects/25

---

## Phase 8 — Datadog Metrics

### runtime.diligence.event.received

12 pontos emitidos (4 por Feature × 3 Features), todos HTTP 202:

| Issue | Event Type | Delivery State | Diligence Status | HTTP |
|---|---|---|---|---|
| 76 | prodops.diligence.capture.started | DONE | Sync In Progress | 202 |
| 76 | prodops.diligence.capture.completed | DONE | Captured | 202 |
| 76 | prodops.diligence.attach.started | DONE | Sync In Progress | 202 |
| 76 | prodops.diligence.attach.completed | DONE | Attached | 202 |
| 77 | prodops.diligence.capture.started | VALIDATING | Sync In Progress | 202 |
| 77 | prodops.diligence.capture.completed | VALIDATING | Captured | 202 |
| 77 | prodops.diligence.attach.started | VALIDATING | Sync In Progress | 202 |
| 77 | prodops.diligence.attach.completed | VALIDATING | Attached | 202 |
| 78 | prodops.diligence.capture.started | HACKING | Sync In Progress | 202 |
| 78 | prodops.diligence.capture.completed | HACKING | Captured | 202 |
| 78 | prodops.diligence.attach.started | HACKING | Sync In Progress | 202 |
| 78 | prodops.diligence.attach.completed | HACKING | Attached | 202 |

**Tags por ponto:** `issue`, `event`, `delivery-state`, `diligence-status`, `delivery-correlation-id`, `diligence-correlation-id`, `service`, `env`, `runtime:prodops`

### runtime.diligence.features.tracked

3 pontos emitidos (1 por Feature), todos HTTP 202:

| Issue | Delivery State | runtime-sync | HTTP |
|---|---|---|---|
| 76 | DONE | In Sync | 202 |
| 77 | VALIDATING | In Sync | 202 |
| 78 | HACKING | In Sync | 202 |

**Tags por ponto:** `issue`, `delivery-state`, `runtime-sync`, `service`, `env`, `runtime:prodops`

---

## Phase 9 — Delivery State Post-Diligence (prova de não-interferência)

```
derived-state-76.json → state: DONE       | last-event-type: prodops.delivery.promote.completed
derived-state-77.json → state: VALIDATING | last-event-type: prodops.delivery.validate.started
derived-state-78.json → state: HACKING    | last-event-type: prodops.delivery.hack.started
```

Idênticos ao estado pré-Diligence. A Journey Diligence não tocou nas timelines Delivery, nem nos derived-states, nem nos campos `oem-state` / `oem-last-event` do GitHub.

---

## Experiment Findings

### Framework Findings

| ID | Encontrado |
|---|---|
| FF-10 | Diligence CloudEvents precisam de campos de cross-referência Delivery (`delivery-correlation-id`, `delivery-last-event-type`, `delivery-derived-state`) que `emit.sh` não suporta. A solução foi construir o JSON do CloudEvent diretamente no script, usando o mesmo padrão do emit.sh mas com campos extras no `data`. O `validate-event.sh` valida apenas o envelope CE 1.0 e não restringe o `data`. |
| FF-11 | O catálogo suporta eventos com `alters-state: false` sem `new-state` (correção do catalog_get para `.get(field, '')` já aplicada no EXP-013). Os 4 eventos Diligence confirmam que o catálogo é extensível para novos Journeys sem modificação do consumer/derive-state.sh. |

### Runtime Findings

| ID | Encontrado |
|---|---|
| RF-6 | Diligence timeline keys (`diligence-76`, `diligence-77`, `diligence-78`) reutilizam o mesmo `append.sh` do Delivery sem modificação — o padrão `timelines/${ISSUE}.json` é agnóstico ao Journey quando o caller controla o ISSUE key. |

---

## Conclusão

**EXP-014 Iteration 1 — COMPLETED ✅**

A hipótese central foi validada:

> *"A Journey Diligence pode rastrear o estado do Runtime de Delivery sem alterar esse estado."*

Evidências:
1. **12 CloudEvents Diligence** emitidos, todos válidos (2 gates), com cross-referência explícita ao Delivery via `delivery-correlation-id`, `delivery-last-event-type`, `delivery-derived-state`
2. **3 timelines Diligence separadas** (`diligence-76/77/78.json`) — as 3 timelines Delivery (`76/77/78.json`) permanecem inalteradas
3. **GitHub Project** com 3 novos campos Diligence — todos os 3 Issues em `Attached / Complete / In Sync` — sem alteração de `oem-state` ou `oem-last-event`
4. **Datadog** com 2 novas métricas (`runtime.diligence.event.received` e `runtime.diligence.features.tracked`) — 15 pontos totais, todos HTTP 202
5. **Delivery states preservados:** DONE / VALIDATING / HACKING idênticos pré e pós ciclo Diligence
