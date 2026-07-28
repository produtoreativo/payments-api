# Relatório — Runtime SDK Foundation (EXP-013)
# ProdOps Framework — Phase 2: Runtime Foundation

> **Data:** 2026-07-26
> **Tipo:** Criação de SDK TypeScript — contratos, modelos e enums
> **Status:** Concluído — typecheck Exit: 0
> **Experimento:** EXP-013
> **Runtime Task:** RT-00 (SDK Foundation — pré-requisito de RT-01..RT-06)

---

## 1. Executive Summary

| Item | Resultado |
|---|---|
| Diretório criado | `runtime/sdk/` |
| Enums | 7 arquivos — valores canônicos COR/OEM |
| Models | 5 arquivos — tipos imutáveis |
| Contracts | 6 arquivos — interfaces comportamentais |
| index.ts | ✅ Exportações públicas consolidadas |
| package.json | ✅ `@prodops/runtime-sdk` v0.1.0 |
| tsconfig.json | ✅ ES2022 / NodeNext / strict |
| README.md | ✅ Estrutura, enums, tabelas de contratos |
| Typecheck | ✅ `tsc --noEmit` Exit: 0 |
| Commit | ❌ Não criado (constraint explícita) |
| Implementações RT-01..RT-06 | ❌ Não realizadas (constraint explícita) |

---

## 2. Estrutura criada

```
runtime/sdk/
├── package.json
├── tsconfig.json
├── README.md
└── src/
    ├── index.ts
    ├── enums/
    │   ├── journey.ts
    │   ├── cycle.ts
    │   ├── phase.ts
    │   ├── state.ts
    │   ├── event-category.ts
    │   ├── producer.ts
    │   └── consumer.ts
    ├── models/
    │   ├── event-instance.ts
    │   ├── derived-state.ts
    │   ├── timeline-state.ts
    │   ├── work-item.ts
    │   └── finding.ts
    └── contracts/
        ├── event.ts
        ├── event-producer.ts
        ├── event-consumer.ts
        ├── timeline.ts
        ├── github-sync.ts
        └── telemetry.ts
```

---

## 3. Princípios aplicados

### Imutabilidade
Todos os campos de interfaces são `readonly`. Arrays são `ReadonlyArray<T>`. Objetos são `Readonly<Record<...>>`.

### Grafo de dependências acíclico
```
enums  ←  models  ←  contracts  ←  index.ts
```
Nenhum arquivo importa de uma camada acima da sua. Verificado via typecheck.

### Sem implementações
Nenhuma `class`, nenhum `function`, nenhum código executável. Apenas `interface`, `enum`, `type`, e `as const`.

### Sem dependências externas
O SDK tem zero dependências de runtime. Apenas `typescript` e `@types/node` como devDependencies.

### Sem dependências de GitHub/Datadog/Journey
As interfaces `GitHubSync` e `Telemetry` definem contratos agnósticos — não importam SDKs de terceiros.

---

## 4. Enums — fonte canônica

| Enum | Arquivo | Fonte canônica |
|---|---|---|
| `Journey` | `enums/journey.ts` | `workspace.yaml` — `oem:journey` options |
| `Cycle` | `enums/cycle.ts` | `workspace.yaml` — `oem:cycle` options |
| `PhaseAction` | `enums/phase.ts` | `workspace.yaml` — `oem:phase` options |
| `State` | `enums/state.ts` | `workspace.yaml` — `oem:state` options |
| `EventCategory` | `enums/event-category.ts` | `event-instance-schema.md` — taxonomia |
| `ProducerType` | `enums/producer.ts` | `event-instance-schema.md` — producer_type |
| `ConsumerType` | `enums/consumer.ts` | OEM framework — papéis de consumidor |

**Nenhum valor novo foi introduzido.** Todos os valores são derivados dos documentos canônicos existentes.

### Valores por enum

**Journey:** `Delivery`, `Diligence`, `Assessment`

**Cycle:** `Bootstrap`, `Hack`, `Sync`, `Finish`, `Ship`, `Validate`, `Promote`, `Rework`

**PhaseAction:** `Started`, `Completed`

**State:** `BOOTSTRAPPING`, `HACKING`, `SYNCING`, `FINISHING`, `SHIPPING`, `VALIDATING`, `PROMOTING`, `DONE`, `BLOCKED`, `REWORKING`

**EventCategory:** `Phase Lifecycle`, `Gate`, `Rework`, `Impediment`, `Diligence`, `Correction`

**ProducerType:** `Human`, `System`, `Agent`

**ConsumerType:** `Timeline`, `GitHubSync`, `Metrics`, `Diligence`, `Assessment`

---

## 5. Models — decisões de design

### EventInstance (`models/event-instance.ts`)

Representa fielmente o schema canônico de `event-instance-schema.md`:

| Campo | Tipo | Obrigatório | Nota |
|---|---|---|---|
| `id` | `string` | ✅ | Globalmente único |
| `event_type` | `string` | ✅ | Nome do Event Type |
| `work_item_id` | `string` | ✅ | 1:1 com Timeline |
| `timestamp` | `string` | ✅ | ISO 8601 com timezone |
| `producer_type` | `ProducerType` | ✅ | Human / System / Agent |
| `producer_identity` | `string` | ✅ | Não vazio |
| `schema_version` | `string` | ✅ | Versão do schema |
| `payload` | `Readonly<Record<string, unknown>>` | ❌ | Dados do evento |
| `evidence_references` | `ReadonlyArray<EvidenceReference>` | ❌ | Referências de evidência |
| `sequence_number` | `number` | ❌ | Ordem dentro da Timeline |
| `notes` | `string` | ❌ | Texto livre |

**Campos derivados (NOT armazenados):** `timeline_id`, `category`, `alters_state`, `new_state`, `evidence_intrinsic`. Estes são computados a partir do `event_type` — não fazem parte do modelo armazenado.

### DerivedState (`models/derived-state.ts`)

Projeção computada, nunca armazenada diretamente. A persistência no GitHub Projects COR é uma otimização de leitura — não é a fonte de verdade.

### Finding (`models/finding.ts`)

Usa `as const` + `type` em vez de enum para `FindingType` e `FindingSeverity`, permitindo uso como valores de string sem instanciação de enum.

---

## 6. Contracts — decisões de design

### `contracts/event.ts`
Re-exporta `EventInstance` e `EvidenceReference` dos models. O contrato canônico do evento É o model — nenhuma duplicação.

### `contracts/timeline.ts`
Define as operações de acesso à Timeline:
- `append`: adiciona evento (implementado por RT-02)
- `replay`: retorna todos os eventos de um Work Item
- `currentState`: retorna `DerivedState` atual
- `lookback`: retorna `DerivedState` em ponto anterior (algoritmo de RT-02)
- `history`: retorna `TimelineState` completo

### `contracts/github-sync.ts`
Importa `DerivedState` e `Finding` — agnóstico ao GitHub Projects v2 API. A implementação de RT-03 escolhe como executar a sincronia.

### `contracts/telemetry.ts`
Define `MetricPoint`, `MetricQuery`, `MetricResult` como tipos auxiliares. Não importa Datadog SDK — RT-04 é responsável pela integração.

---

## 7. Verificação de typecheck

```
$ cd runtime/sdk && npx tsc --noEmit
Exit: 0
```

Nenhum erro de tipo. Nenhum aviso. Grafo de dependências acíclico confirmado pelo compilador.

---

## 8. O que o SDK não faz (by design)

| Item | Razão |
|---|---|
| Nenhuma implementação de classe | SDK é fundação de contratos — RT-01..RT-06 implementam |
| Nenhum código executável | Apenas tipos em tempo de compilação |
| Nenhuma dependência de runtime | Zero peso em produção |
| Nenhum acoplamento a GitHub/Datadog | Contratos agnósticos de backend |
| Nenhum `Discovery` ou `Operation` no Journey enum | Não definidos no COR do piloto (EXP-013) |

---

## 9. Próximos passos

| Componente | Usa do SDK | Task GitHub |
|---|---|---|
| RT-01 Event Producer | `EventProducer`, `EventInstance`, `ProducerType` | #70 |
| RT-02 Timeline Processor | `Timeline`, `EventConsumer`, `DerivedState` | #71 |
| RT-03 GitHub Synchronizer | `GitHubSync`, `EventConsumer`, `DerivedState` | #72 |
| RT-04 Datadog Adapter | `Telemetry`, `EventConsumer`, `MetricPoint` | #73 |
| RT-05 Delivery Dashboard | `Timeline`, `TimelineState`, `WorkItem` | #74 |
| RT-06 Diligence Dashboard | `Finding`, `DerivedState`, `ConsumerType` | #75 |

---

## 10. Artefatos desta etapa

| Artefato | Localização |
|---|---|
| SDK Foundation | `runtime/sdk/` |
| Enums canônicos | `runtime/sdk/src/enums/` (7 arquivos) |
| Models OEM | `runtime/sdk/src/models/` (5 arquivos) |
| Contracts Runtime | `runtime/sdk/src/contracts/` (6 arquivos) |
| Public API | `runtime/sdk/src/index.ts` |
| Este documento | `prodops/documentation-review-runtime-sdk-foundation.md` |
