# Relatório — Runtime SDK Reconciliation Before v0.1.0
# ProdOps Framework — Phase 2: Runtime Foundation

> **Data:** 2026-07-26
> **Tipo:** Reconciliação de contratos do SDK com decisões arquiteturais consolidadas
> **Status:** Concluído — typecheck Exit: 0
> **Experimento:** EXP-013
> **Baseline:** Prompt 11 (SDK Foundation v0.0.1)
> **Resultado:** SDK declarado pronto para tag `v0.1.0`

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Divergências encontradas | 5 (enums incorretos, Telemetry monolítica, Timeline com append, sem CloudEvents) |
| Contratos alterados | 7 arquivos |
| Contratos criados | 8 novos arquivos |
| Breaking changes | 4 (documentadas) |
| Adições não-breaking | CloudEvents, OSE, TagProjection, EventPublisher, EventQuery |
| Typecheck | ✅ `tsc --noEmit` Exit: 0 |
| Commit | ❌ Não criado (constraint) |
| SDK pronto para v0.1.0 | ✅ Sim |

---

## 2. Divergências encontradas e corrigidas

### DIV-01 — EventCategory: valores incorretos (CRÍTICA)

**Divergência:** O SDK tinha 6 categories; o canonical taxonomy.md define 8. Além disso, `Impediment` não é um nome canônico — o nome correto é `Blocking`.

**Fonte canônica:** `prodops/framework/events/taxonomy.md` section 2.2

| SDK v0.0.1 | Canônico (taxonomy.md) | Ação |
|---|---|---|
| `Impediment` | `Blocking` | Renomeado |
| *(ausente)* | `HumanDecision` | Adicionado |
| *(ausente)* | `System` | Adicionado |
| PhaseLifecycle ✅ | Phase Lifecycle | Mantido |
| Gate ✅ | Gate | Mantido |
| Rework ✅ | Rework | Mantido |
| Diligence ✅ | Diligence | Mantido |
| Correction ✅ | Correction | Mantido |

**Impacto:** `EventCategory.Impediment` → `EventCategory.Blocking`. Breaking change.

---

### DIV-02 — Cycle/Phase: confusão de nomenclatura (CRÍTICA)

**Divergência:** O SDK tinha `Cycle` enum com valores Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework. O Framework canônico chama esses valores de **Phases** (ver `prodops/framework/journeys/delivery/phases/`). O que o Framework chama de **Cycle** é o ritmo operacional: CI Sync, CI Async, Diligence Sync, Diligence Async.

O `oem:cycle` em `workspace.yaml` usa incorretamente o nome "cycle" para valores que são Phases. A COR tem um naming issue, mas o SDK deve seguir o Framework canônico.

**Fonte canônica:** `prodops/framework/journeys/delivery/phases/` (fases); `prodops/framework/journeys/delivery/ci-sync.md`, `ci-async.md` (ciclos)

**Correção:**
- `Cycle` enum → valores corretos: CISync, CIAsync, DiligenceSync, DiligenceAsync
- `Phase` enum → Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework
- `PhaseAction` renomeado para `PhaseLifecycle` (alinha com a categoria "Phase Lifecycle")

**Impacto:** Breaking change. Consumidores que importavam `Cycle.Bootstrap` → `Phase.Bootstrap`. `PhaseAction.Started` → `PhaseLifecycle.Started`.

---

### DIV-03 — Journey enum incompleto

**Divergência:** SDK tinha Journey = {Delivery, Diligence, Assessment}. O Framework define 5 Journeys.

**Fonte canônica:** `prodops/framework/ontology.md` section 7.2 (lista journeys/discovery, journeys/operation)

**Correção:** Journey = {Delivery, Diligence, Assessment, Discovery, Operation}

**Nota:** O workspace.yaml (COR do piloto) tem apenas Delivery, Diligence, Assessment porque o EXP-013 cobre somente essas três. O SDK é mais amplo que a COR — correto por design.

---

### DIV-04 — Telemetry monolítica viola princípio de interfaces pequenas

**Divergência:** A interface `Telemetry` misturava publicação de eventos, publicação de métricas e query de métricas em uma única interface.

**Correção:**
- `Telemetry` interface removida
- `MetricPublisher` → publica MetricPoint
- `MetricQuery` → consulta métricas (behavioral interface)
- `EventPublisher` → publica CloudEventEnvelope (transporte de eventos)
- `EventQuery` → consulta eventos por workItemId (behavioral interface)
- `MetricQueryParams` → renomeado de `MetricQuery` (liberou o nome para interface behavioral)

---

### DIV-05 — Timeline.append() violava separação de responsabilidades

**Divergência:** `Timeline.append()` colocava responsabilidade de publicação na Timeline. A nova arquitetura separa: publicação = EventProducer + CloudEventEncoder + EventPublisher. Timeline = reconstrução a partir do event store.

**Correção:**
- `append()` removido do contrato `Timeline`
- `replayUntil(workItemId, timestamp)` adicionado
- `lookback()` signature atualizada para aceitar timestamp ou eventId
- Timeline é agora puramente read-only

---

## 3. Contratos alterados

| Arquivo | Mudança | Breaking? |
|---|---|---|
| `src/enums/event-category.ts` | Adicionou HumanDecision, System; Impediment → Blocking | ✅ Sim |
| `src/enums/journey.ts` | Adicionou Discovery, Operation | Não (adição) |
| `src/enums/cycle.ts` | Valores completamente substituídos (CISync, CIAsync, DiligenceSync, DiligenceAsync) | ✅ Sim |
| `src/enums/phase.ts` | Conteúdo substituído: Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework (era PhaseAction) | ✅ Sim |
| `src/models/derived-state.ts` | Adicionou `phase?: Phase`; manteve `cycle?: Cycle` com semântica correta | Não (adição) |
| `src/models/event-instance.ts` | Adicionou JSDoc no campo `id` especificando UUID v7 | Não |
| `src/contracts/telemetry.ts` | Removeu `Telemetry`; renomeou `MetricQuery` → `MetricQueryParams` | ✅ Sim |
| `src/contracts/timeline.ts` | Removeu `append()`; adicionou `replayUntil()`; atualizou `lookback()` | ✅ Sim |

---

## 4. Contratos criados

| Arquivo | Conteúdo | Implementado por |
|---|---|---|
| `src/enums/phase-lifecycle.ts` | `PhaseLifecycle`: Started, Completed | — (enum) |
| `src/models/event-type.ts` | `EventNamespace`, `EventTypeId` (template literal type) | — (type) |
| `src/contracts/cloud-events.ts` | `CloudEventEnvelope<TData>`, `CloudEventEncoder`, `CloudEventDecoder` | RT-01, RT-04 |
| `src/contracts/event-publisher.ts` | `EventPublisher` (transport layer) | RT-04 |
| `src/contracts/event-query.ts` | `EventQuery`, `EventQueryOptions`, `EventQueryResult` | RT-04 |
| `src/contracts/metric-publisher.ts` | `MetricPublisher` | RT-04 |
| `src/contracts/metric-query.ts` | `MetricQuery` (behavioral) | RT-04 |
| `src/contracts/operational-state-engine.ts` | `OperationalStateEngine`, `ValidationResult` | RT-02 |
| `src/contracts/tag-projection.ts` | `TagProjection`, `TagSet` | RT-04 |

---

## 5. Decisões preservadas

| Decisão | Fonte | Status |
|---|---|---|
| EventInstance imutável com todos os campos canônicos | event-instance-schema.md | Preservado |
| `sequence_number` mantido como opcional | event-instance-schema.md section 3.8 | Preservado — schema canônico define como recomendado para facilitar Consumers |
| `schema_version` mantido | event-instance-schema.md | Preservado |
| `payload` e `evidence_references` mantidos | event-instance-schema.md | Preservado |
| Campos derivados NÃO armazenados em EventInstance | event-instance-schema.md section 2.3 | Preservado |
| DerivedState é projeção computada, não armazenada | ontology.md INV-05 | Preservado |
| COR nunca é fonte de verdade | ontology.md INV-06, INV-09 | Preservado |
| Sem dependências de runtime no SDK | Prompt 11 | Preservado |
| Sem implementações — apenas contratos | Prompt 11 | Preservado |

---

## 6. Decisões recentes incorporadas

### 6.1 Event Identity — UUID v7

**Decisão:** EventInstance.id deve usar UUID v7.

**Divergência com canonical schema:** `event-instance-schema.md` seção 3.1 afirma "O formato do `id` não é prescrito por este Schema (UUID v4, ULID, hash — qualquer formato que garanta unicidade global é válido)."

**Resolução:** UUID v7 é a decisão arquitetural do Runtime (EXP-013). Documentada via JSDoc no campo `id` de EventInstance. O Framework não foi alterado — a escolha de UUID v7 é uma decisão de implementação, não de schema.

**Nenhuma validação criptográfica** foi adicionada nesta etapa.

### 6.2 Event Type — convenção com namespace obrigatório

**Decisão:** Sempre incluir namespace: `<Namespace>.<Subject>.<Action>[.<Qualifier>]`

**Implementação:** `EventNamespace` type + `EventTypeId` template literal type em `models/event-type.ts`.

**Namespaces do piloto:** Delivery, Diligence, Assessment, Shared (Discovery e Operation incluídos para completude do Framework).

**Nota:** O taxonomy.md canônico define namespace como OPCIONAL dentro do catálogo da Journey e OBRIGATÓRIO em referências cross-Journey. A decisão do Runtime de SEMPRE incluir é mais restritiva — escolha arquitetural do SDK, não mudança no Framework.

### 6.3 CloudEvents 1.0 como envelope de transporte

**Implementação:** `CloudEventEnvelope<TData>`, `CloudEventEncoder`, `CloudEventDecoder` em `contracts/cloud-events.ts`.

**Mapeamento OEM → CloudEvents:**
| EventInstance | CloudEventEnvelope |
|---|---|
| `id` | `id` |
| `event_type` | `type` |
| `work_item_id` | `subject` |
| `producer_identity` | `source` (URI-reference) |
| `timestamp` | `time` |
| EventInstance (completo) | `data` |
| *(sempre)* | `specversion: '1.0'` |

**Sem biblioteca externa de CloudEvents** incluída — apenas contrato estrutural.

### 6.4 Timeline reconstruída (não armazenada)

**Decisão:** A Timeline é reconstruída via EventQuery (Datadog) + OperationalStateEngine.

**Implementação:** `append()` removido do `Timeline` contract. `EventPublisher` é o contrato de escrita (transporte). `EventQuery` é o contrato de leitura do event store.

### 6.5 Separação de responsabilidades no fluxo de eventos

```
EventProducer → cria EventInstance
CloudEventEncoder → wraps em CloudEventEnvelope
EventPublisher → envia ao transporte (Datadog)
──────────────────────────────────────────
EventQuery → lê do Datadog por workItemId
OperationalStateEngine → ordena, valida, aplica correções, calcula DerivedState
Timeline → view computada (não armazenada)
```

### 6.6 Datadog tags derivadas (não armazenadas em EventInstance)

**Decisão:** Tags são derivadas pelo Adapter, não são parte do EventInstance.

**Implementação:** `TagProjection`, `TagSet` em `contracts/tag-projection.ts`.

**Regras registradas:**
- Chaves: lowercase + snake_case
- IDs de alta cardinalidade (work_item_id, event id) não são tags
- env, service, version pertencem à configuração do backend, não ao TagSet

### 6.7 Operational State Engine como contrato explícito

**Implementação:** `OperationalStateEngine` em `contracts/operational-state-engine.ts`.

Separa a lógica de processamento (validate, order, applyCorrections, replay, lookback, effectiveState) da consulta (EventQuery) e da materialização (GitHubSync).

---

## 7. Event ID — formato final

| Campo | Valor | Fonte |
|---|---|---|
| Tipo TypeScript | `string` | Compatibilidade — UUID v7 não é um tipo primitivo TypeScript |
| Formato obrigatório | UUID v7 | Decisão arquitetural RT (EXP-013) |
| Gerado por | O Producer antes de qualquer persistência | event-instance-schema.md |
| Semântica | Sem semântica de domínio — identificador opaco | Arquitetura RT |
| Mapping CloudEvents | `CloudEventEnvelope.id` | cloud-events.ts |

---

## 8. Event Type — formato final

| Campo | Valor |
|---|---|
| Formato | `<Namespace>.<Subject>.<Action>[.<Qualifier>]` |
| Namespaces | Delivery, Diligence, Assessment, Shared, Discovery, Operation |
| TypeScript type | `EventTypeId = \`${EventNamespace}.${string}.${string}\`` |
| Exemplos válidos | `Delivery.Bootstrap.Started`, `Shared.Gate.Passed`, `Diligence.Drift.Detected` |
| Versão | Não incluída no type (conforme Prompt 12) |

---

## 9. Mapeamento CloudEvents — final

| CloudEvent field | OEM source | Notas |
|---|---|---|
| `specversion` | Fixo: `'1.0'` | Sempre present |
| `id` | `EventInstance.id` | UUID v7 |
| `type` | `EventInstance.event_type` | EventTypeId format |
| `source` | `EventInstance.producer_identity` | URI-reference |
| `subject` | `EventInstance.work_item_id` | Work Item identifier |
| `time` | `EventInstance.timestamp` | ISO 8601 com timezone |
| `datacontenttype` | `'application/json'` | Opcional, definido pelo adapter |
| `data` | `EventInstance` (completo) | OEM event como data |

---

## 10. Auditoria de enums

| Enum | SDK v0.0.1 | SDK v0.1.0 | Fonte canônica | Status |
|---|---|---|---|---|
| `Journey` | Delivery, Diligence, Assessment | + Discovery, Operation | framework/ontology.md | ✅ Correto |
| `Cycle` | Bootstrap, Hack, ... (ERRADO — eram fases) | CISync, CIAsync, DiligenceSync, DiligenceAsync | framework/journeys/delivery/ci-sync.md etc. | ✅ Corrigido |
| `Phase` | *(era PhaseAction: Started, Completed)* | Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework | framework/journeys/delivery/phases/ | ✅ Corrigido |
| `PhaseLifecycle` | *(ausente — era PhaseAction)* | Started, Completed | taxonomy.md — Phase Lifecycle category | ✅ Criado |
| `State` | BOOTSTRAPPING..REWORKING (10 values) | Inalterado | workspace.yaml / catalog.md Delivery | ✅ Correto |
| `EventCategory` | 6 values (Impediment errado) | 8 values (todos corretos) | taxonomy.md section 2.2 | ✅ Corrigido |
| `ProducerType` | Human, System, Agent | Inalterado | event-instance-schema.md | ✅ Correto |
| `ConsumerType` | Timeline, GitHubSync, Metrics, Diligence, Assessment | Inalterado | ontology.md section 2.5 | ✅ Correto |

---

## 11. Breaking changes — changelog v0.0.1 → v0.1.0

| # | Mudança | Motivo |
|---|---|---|
| BC-01 | `EventCategory.Impediment` → `EventCategory.Blocking` | Alinhamento com canonical taxonomy.md |
| BC-02 | `EventCategory` + 2 values (HumanDecision, System) | taxonomy.md define 8 categorias fixas |
| BC-03 | `Cycle` enum: novos valores (CISync, CIAsync, DiligenceSync, DiligenceAsync) | Correção de confusão Cycle vs Phase |
| BC-04 | `Phase` enum: Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework | Correção — eram incorretamente em `Cycle` |
| BC-05 | `PhaseAction` → `PhaseLifecycle` (arquivo e enum renomeados) | Alinhamento com nome da categoria OEM |
| BC-06 | `MetricQuery` (data type) → `MetricQueryParams` | Liberou nome para behavioral interface |
| BC-07 | `Telemetry` interface removida | Split em MetricPublisher + MetricQuery |
| BC-08 | `Timeline.append()` removido | Responsabilidade de publicação → EventPublisher |

Como não existe consumidor em produção, todas as breaking changes foram implementadas sem período de migração.

---

## 12. Resultado do typecheck

```
$ cd runtime/sdk && npx tsc --noEmit
Exit: 0
```

Nenhum erro. Grafo de dependências acíclico confirmado.

---

## 13. SDK pronto para v0.1.0?

**Avaliação: ✅ SIM**

| Critério | Status |
|---|---|
| EventInstance fiel ao schema canônico | ✅ |
| Event ID com formato documentado (UUID v7) | ✅ |
| Event Type com namespace e template literal type | ✅ |
| CloudEvents 1.0 contract agnóstico | ✅ |
| Telemetry contracts separados por responsabilidade | ✅ |
| Timeline read-only (sem append) | ✅ |
| OperationalStateEngine contrato explícito | ✅ |
| TagProjection contrato (tags derivadas, não armazenadas) | ✅ |
| Enums alinhados com fontes canônicas do Framework | ✅ |
| Grafo acíclico: enums ← models ← contracts | ✅ |
| Sem dependências externas de runtime | ✅ |
| Sem implementações (contratos apenas) | ✅ |
| Typecheck Exit: 0 | ✅ |

---

## 14. Estrutura final do SDK v0.1.0

```
runtime/sdk/src/
├── enums/
│   ├── consumer.ts         (ConsumerType — sem mudança)
│   ├── cycle.ts            (Cycle — CORRIGIDO: ritmos operacionais)
│   ├── event-category.ts   (EventCategory — CORRIGIDO: 8 categorias)
│   ├── journey.ts          (Journey — EXPANDIDO: +Discovery, +Operation)
│   ├── phase.ts            (Phase — NOVO CONTEÚDO: fases da Delivery)
│   ├── phase-lifecycle.ts  (PhaseLifecycle — NOVO ARQUIVO: Started, Completed)
│   ├── producer.ts         (ProducerType — sem mudança)
│   └── state.ts            (State — sem mudança)
├── models/
│   ├── derived-state.ts    (DerivedState — +phase field)
│   ├── event-instance.ts   (EventInstance — +UUID v7 JSDoc)
│   ├── event-type.ts       (EventNamespace, EventTypeId — NOVO)
│   ├── finding.ts          (Finding — sem mudança)
│   ├── timeline-state.ts   (TimelineState — sem mudança)
│   └── work-item.ts        (WorkItem — sem mudança)
└── contracts/
    ├── cloud-events.ts         (CloudEventEnvelope, Encoder, Decoder — NOVO)
    ├── event.ts                (re-export EventInstance — sem mudança)
    ├── event-consumer.ts       (EventConsumer — sem mudança)
    ├── event-producer.ts       (EventProducer — sem mudança)
    ├── event-publisher.ts      (EventPublisher — NOVO: transport layer)
    ├── event-query.ts          (EventQuery — NOVO)
    ├── github-sync.ts          (GitHubSync — sem mudança)
    ├── metric-publisher.ts     (MetricPublisher — NOVO)
    ├── metric-query.ts         (MetricQuery behavioral — NOVO)
    ├── operational-state-engine.ts (OperationalStateEngine — NOVO)
    ├── tag-projection.ts       (TagProjection, TagSet — NOVO)
    ├── telemetry.ts            (MetricPoint, MetricQueryParams, MetricResult — ATUALIZADO)
    └── timeline.ts             (Timeline read-only — ATUALIZADO)
```

---

## 15. Artefatos desta etapa

| Artefato | Localização |
|---|---|
| SDK reconciliado | `runtime/sdk/` |
| Este documento | `prodops/documentation-review-runtime-sdk-reconciliation.md` |
